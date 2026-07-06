-- ============================================================================
-- The Gist — Community News & Gist Platform
-- Initial schema, state machine constraints, and row-level security.
-- Run this in the Supabase SQL editor (or `supabase db push`) on a fresh project.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- Enums
-- ----------------------------------------------------------------------------
create type user_role as enum ('reader', 'writer', 'editor');
create type user_status as enum ('active', 'suspended');
create type article_status as enum ('draft', 'in_review', 'published', 'rejected');
create type comment_status as enum ('visible', 'hidden', 'deleted');
create type review_action as enum ('approve', 'reject', 'request_changes');

-- ----------------------------------------------------------------------------
-- Profiles (mirrors auth.users, adds role/status)
-- ----------------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  avatar_url text,
  role user_role not null default 'reader',
  status user_status not null default 'active',
  created_at timestamptz not null default now()
);

-- Auto-create a profile row whenever a new auth user signs up.
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    'reader'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- Categories & Tags
-- ----------------------------------------------------------------------------
create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique
);

create table tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

-- ----------------------------------------------------------------------------
-- Articles — the content state machine
-- ----------------------------------------------------------------------------
create table articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text not null unique,
  body text not null default '',
  cover_image_url text,
  status article_status not null default 'draft',
  author_id uuid not null references profiles(id) on delete cascade,
  category_id uuid references categories(id) on delete set null,
  read_count integer not null default 0,
  review_note text,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table article_tags (
  article_id uuid references articles(id) on delete cascade,
  tag_id uuid references tags(id) on delete cascade,
  primary key (article_id, tag_id)
);

create index idx_articles_status on articles(status);
create index idx_articles_author on articles(author_id);
create index idx_articles_category on articles(category_id);

-- Keep updated_at current, and stamp published_at the moment a story goes live.
create function public.touch_article()
returns trigger as $$
begin
  new.updated_at = now();
  if new.status = 'published' and old.status is distinct from 'published' then
    new.published_at = now();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_touch_article
  before update on articles
  for each row execute procedure public.touch_article();

-- ----------------------------------------------------------------------------
-- Review log — every editorial decision, feeding "editor feedback on rejected pieces"
-- ----------------------------------------------------------------------------
create table review_logs (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references articles(id) on delete cascade,
  editor_id uuid not null references profiles(id),
  action review_action not null,
  note text,
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- Comments
-- ----------------------------------------------------------------------------
create table comments (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references articles(id) on delete cascade,
  author_id uuid not null references profiles(id) on delete cascade,
  body text not null,
  status comment_status not null default 'visible',
  created_at timestamptz not null default now()
);

create index idx_comments_article on comments(article_id);

-- ----------------------------------------------------------------------------
-- read_count increment — called from the article page via an RPC so it's an
-- atomic server-side increment rather than a client read-modify-write.
-- ----------------------------------------------------------------------------
create function public.increment_read_count(article_slug text)
returns void as $$
begin
  update articles set read_count = read_count + 1
  where slug = article_slug and status = 'published';
end;
$$ language plpgsql security definer;

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table profiles enable row level security;
alter table categories enable row level security;
alter table tags enable row level security;
alter table articles enable row level security;
alter table article_tags enable row level security;
alter table comments enable row level security;
alter table review_logs enable row level security;

-- Small helper: current user's role, without recursive RLS lookups.
create function public.current_role()
returns user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql stable security definer;

-- ---- profiles ----
create policy "Profiles are publicly readable"
  on profiles for select using (true);

create policy "Users can update their own profile"
  on profiles for update using (auth.uid() = id);

create policy "Editors can update any profile (suspend, role changes)"
  on profiles for update using (public.current_role() = 'editor');

-- ---- categories / tags ----
create policy "Categories are publicly readable"
  on categories for select using (true);
create policy "Editors manage categories"
  on categories for insert with check (public.current_role() = 'editor');
create policy "Editors update categories"
  on categories for update using (public.current_role() = 'editor');

create policy "Tags are publicly readable"
  on tags for select using (true);
create policy "Writers and editors create tags"
  on tags for insert with check (public.current_role() in ('writer', 'editor'));

-- ---- articles ----
-- Public can only ever see published articles.
create policy "Anyone can read published articles"
  on articles for select using (status = 'published');

-- Authors can see (and edit) their own articles regardless of status.
create policy "Authors can read their own articles"
  on articles for select using (auth.uid() = author_id);

create policy "Editors can read every article"
  on articles for select using (public.current_role() = 'editor');

create policy "Writers create their own drafts"
  on articles for insert with check (
    auth.uid() = author_id and public.current_role() in ('writer', 'editor')
  );

-- Authors can edit their own article only while it's draft or rejected
-- (i.e. not while it's mid-review or already published — that's the editor's call).
create policy "Authors edit own draft/rejected articles"
  on articles for update using (
    auth.uid() = author_id and status in ('draft', 'rejected')
  );

-- Editors can update any article (approve, reject, feature, edit status/notes).
create policy "Editors update any article"
  on articles for update using (public.current_role() = 'editor');

-- ---- article_tags ----
create policy "Article tags are publicly readable"
  on article_tags for select using (true);
create policy "Authors manage tags on their own articles"
  on article_tags for all using (
    exists (select 1 from articles a where a.id = article_id and a.author_id = auth.uid())
    or public.current_role() = 'editor'
  );

-- ---- comments ----
create policy "Visible comments are publicly readable"
  on comments for select using (status = 'visible');

create policy "Editors read all comments"
  on comments for select using (public.current_role() = 'editor');

create policy "Signed-in users can comment"
  on comments for insert with check (
    auth.uid() = author_id
    and exists (select 1 from profiles p where p.id = auth.uid() and p.status = 'active')
  );

create policy "Editors moderate any comment"
  on comments for update using (public.current_role() = 'editor');

create policy "Authors can delete their own comment"
  on comments for update using (auth.uid() = author_id);

-- ---- review_logs ----
create policy "Editors create review logs"
  on review_logs for insert with check (public.current_role() = 'editor');

create policy "Authors read review logs on their own articles"
  on review_logs for select using (
    exists (select 1 from articles a where a.id = article_id and a.author_id = auth.uid())
  );

create policy "Editors read all review logs"
  on review_logs for select using (public.current_role() = 'editor');

-- ============================================================================
-- Storage — cover image bucket
-- Create the bucket itself in Dashboard → Storage → New bucket → "covers"
-- (public bucket), then run the policies below.
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

create policy "Cover images are publicly readable"
  on storage.objects for select using (bucket_id = 'covers');

create policy "Writers and editors upload cover images"
  on storage.objects for insert with check (
    bucket_id = 'covers' and public.current_role() in ('writer', 'editor')
  );

create policy "Writers and editors update their own cover images"
  on storage.objects for update using (
    bucket_id = 'covers' and public.current_role() in ('writer', 'editor')
  );

-- ============================================================================
-- Seed data (matches "Shipped when" — seed content already populated)
-- ============================================================================
insert into categories (name, slug) values
  ('Politics', 'politics'),
  ('Culture', 'culture'),
  ('Business', 'business'),
  ('Campus', 'campus'),
  ('Opinion', 'opinion'),
  ('Sports', 'sports');
