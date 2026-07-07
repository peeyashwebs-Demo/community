-- ============================================================================
-- THE GIST — COMPLETE SETUP (run this once, in order, top to bottom)
--
-- This single file replaces the old numbered migrations (0001-0007). Use it
-- on a FRESH Supabase project. Paste this whole file into the SQL editor and
-- click Run once — it builds the schema, security rules, feedback, likes,
-- owner bootstrap, and seeds 3 writer accounts + 60 published articles.
--
-- If you're re-running this on a project that already has some of these
-- objects, the DROP statements at the top clear them out first so this is
-- safe to run more than once.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Clean slate (safe no-ops on a brand-new project)
-- ----------------------------------------------------------------------------
drop table if exists review_logs cascade;
drop table if exists likes cascade;
drop table if exists comments cascade;
drop table if exists article_tags cascade;
drop table if exists articles cascade;
drop table if exists tags cascade;
drop table if exists categories cascade;
drop table if exists feedback cascade;
drop table if exists profiles cascade;

drop function if exists public.handle_new_user() cascade;
drop function if exists public.touch_article() cascade;
drop function if exists public.increment_read_count(text) cascade;
drop function if exists public.current_role() cascade;
drop function if exists public.prevent_role_escalation() cascade;
drop function if exists public.claim_first_editor() cascade;
drop function if exists public.toggle_like(uuid) cascade;

drop type if exists user_role cascade;
drop type if exists user_status cascade;
drop type if exists article_status cascade;
drop type if exists comment_status cascade;
drop type if exists review_action cascade;

delete from auth.users where email like '%@seed.thegist.demo';

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- 1. Enums
-- ----------------------------------------------------------------------------
create type user_role as enum ('reader', 'writer', 'editor');
create type user_status as enum ('active', 'suspended');
create type article_status as enum ('draft', 'in_review', 'published', 'rejected');
create type comment_status as enum ('visible', 'hidden', 'deleted');
create type review_action as enum ('approve', 'reject', 'request_changes');

-- ----------------------------------------------------------------------------
-- 2. Profiles + signup trigger (includes the writer-role-at-signup fix from
--    the start, so there's no separate "0007 fix" needed this time)
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

create function public.handle_new_user()
returns trigger as $$
declare
  requested text := new.raw_user_meta_data->>'requested_role';
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    case when requested = 'writer' then 'writer'::user_role else 'reader'::user_role end
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ----------------------------------------------------------------------------
-- 3. Categories & Tags
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
-- 4. Articles — the content state machine (like_count included from the start)
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
  like_count integer not null default 0,
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
-- 5. Review log
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
-- 6. Comments
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
-- 7. Feedback
-- ----------------------------------------------------------------------------
create table feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete set null,
  name text not null,
  email text,
  message text not null,
  rating smallint check (rating between 1 and 5),
  status text not null default 'new' check (status in ('new', 'reviewed')),
  created_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- 8. Likes
-- ----------------------------------------------------------------------------
create table likes (
  article_id uuid not null references articles(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (article_id, user_id)
);

create index idx_likes_article on likes(article_id);

-- ----------------------------------------------------------------------------
-- 9. Functions: read-count increment, current-role helper, toggle-like,
--    prevent-role-escalation, claim-first-editor
-- ----------------------------------------------------------------------------
create function public.increment_read_count(article_slug text)
returns void as $$
begin
  update articles set read_count = read_count + 1
  where slug = article_slug and status = 'published';
end;
$$ language plpgsql security definer;

create function public.current_role()
returns user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql stable security definer;

create function public.prevent_role_escalation()
returns trigger as $$
begin
  if auth.uid() is not null and public.current_role() <> 'editor' then
    if not (old.role = 'reader' and new.role = 'writer') then
      new.role = old.role;
    end if;
    new.status = old.status;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_prevent_role_escalation
  before update on profiles
  for each row execute procedure public.prevent_role_escalation();

create function public.claim_first_editor()
returns boolean as $$
declare
  editor_count int;
begin
  if auth.uid() is null then
    return false;
  end if;

  select count(*) into editor_count from profiles where role = 'editor';

  if editor_count > 0 then
    return false;
  end if;

  update profiles set role = 'editor' where id = auth.uid();
  return true;
end;
$$ language plpgsql security definer;

grant execute on function public.claim_first_editor() to authenticated;

create function public.toggle_like(p_article_id uuid)
returns boolean as $$
declare
  already_liked boolean;
begin
  if auth.uid() is null then
    raise exception 'Must be signed in to like a story';
  end if;

  select exists(
    select 1 from likes where article_id = p_article_id and user_id = auth.uid()
  ) into already_liked;

  if already_liked then
    delete from likes where article_id = p_article_id and user_id = auth.uid();
    update articles set like_count = greatest(0, like_count - 1) where id = p_article_id;
    return false;
  else
    insert into likes (article_id, user_id) values (p_article_id, auth.uid());
    update articles set like_count = like_count + 1 where id = p_article_id;
    return true;
  end if;
end;
$$ language plpgsql security definer;

grant execute on function public.toggle_like(uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 10. Row Level Security
-- ----------------------------------------------------------------------------
alter table profiles enable row level security;
alter table categories enable row level security;
alter table tags enable row level security;
alter table articles enable row level security;
alter table article_tags enable row level security;
alter table comments enable row level security;
alter table review_logs enable row level security;
alter table feedback enable row level security;
alter table likes enable row level security;

create policy "Profiles are publicly readable" on profiles for select using (true);
create policy "Users can update their own profile" on profiles for update using (auth.uid() = id);
create policy "Editors can update any profile" on profiles for update using (public.current_role() = 'editor');

create policy "Categories are publicly readable" on categories for select using (true);
create policy "Editors manage categories" on categories for insert with check (public.current_role() = 'editor');
create policy "Editors update categories" on categories for update using (public.current_role() = 'editor');

create policy "Tags are publicly readable" on tags for select using (true);
create policy "Writers and editors create tags" on tags for insert with check (public.current_role() in ('writer', 'editor'));

create policy "Anyone can read published articles" on articles for select using (status = 'published');
create policy "Authors can read their own articles" on articles for select using (auth.uid() = author_id);
create policy "Editors can read every article" on articles for select using (public.current_role() = 'editor');
create policy "Writers create their own drafts" on articles for insert with check (
  auth.uid() = author_id and public.current_role() in ('writer', 'editor')
);
create policy "Authors edit own draft/rejected articles" on articles for update using (
  auth.uid() = author_id and status in ('draft', 'rejected')
);
create policy "Editors update any article" on articles for update using (public.current_role() = 'editor');

create policy "Article tags are publicly readable" on article_tags for select using (true);
create policy "Authors manage tags on their own articles" on article_tags for all using (
  exists (select 1 from articles a where a.id = article_id and a.author_id = auth.uid())
  or public.current_role() = 'editor'
);

create policy "Visible comments are publicly readable" on comments for select using (status = 'visible');
create policy "Editors read all comments" on comments for select using (public.current_role() = 'editor');
create policy "Signed-in users can comment" on comments for insert with check (
  auth.uid() = author_id
  and exists (select 1 from profiles p where p.id = auth.uid() and p.status = 'active')
);
create policy "Editors moderate any comment" on comments for update using (public.current_role() = 'editor');
create policy "Authors can delete their own comment" on comments for update using (auth.uid() = author_id);

create policy "Editors create review logs" on review_logs for insert with check (public.current_role() = 'editor');
create policy "Authors read review logs on their own articles" on review_logs for select using (
  exists (select 1 from articles a where a.id = article_id and a.author_id = auth.uid())
);
create policy "Editors read all review logs" on review_logs for select using (public.current_role() = 'editor');

create policy "Anyone can submit feedback" on feedback for insert with check (true);
create policy "Editors read feedback" on feedback for select using (public.current_role() = 'editor');
create policy "Editors update feedback status" on feedback for update using (public.current_role() = 'editor');

create policy "Likes are publicly readable" on likes for select using (true);
create policy "Signed-in active users can like" on likes for insert with check (
  auth.uid() = user_id
  and exists (select 1 from profiles p where p.id = auth.uid() and p.status = 'active')
);
create policy "Users remove their own like" on likes for delete using (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 11. Storage bucket for cover images
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

create policy "Cover images are publicly readable" on storage.objects for select using (bucket_id = 'covers');
create policy "Writers and editors upload cover images" on storage.objects for insert with check (
  bucket_id = 'covers' and public.current_role() in ('writer', 'editor')
);
create policy "Writers and editors update their own cover images" on storage.objects for update using (
  bucket_id = 'covers' and public.current_role() in ('writer', 'editor')
);

-- ----------------------------------------------------------------------------
-- 12. Explicit Data API grants (some Supabase projects require these)
-- ----------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 13. Seed categories
-- ----------------------------------------------------------------------------
insert into categories (name, slug) values
  ('Politics', 'politics'),
  ('Culture', 'culture'),
  ('Business', 'business'),
  ('Campus', 'campus'),
  ('Opinion', 'opinion'),
  ('Sports', 'sports');

-- ----------------------------------------------------------------------------
-- 14. Seed 3 demo writer accounts
-- ----------------------------------------------------------------------------
do $$
declare
  writer0_id uuid := gen_random_uuid();
  writer1_id uuid := gen_random_uuid();
  writer2_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer0_id, 'authenticated', 'authenticated',
    'ada.chukwu@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Ada Chukwu"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer0_id;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer1_id, 'authenticated', 'authenticated',
    'tari.amadi@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Tari Amadi"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer1_id;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, confirmation_token, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', writer2_id, 'authenticated', 'authenticated',
    'chuka.eze@seed.thegist.demo', crypt('SeedWriter!2026', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{"name":"Chuka Eze"}', '', ''
  );
  update public.profiles set role = 'writer' where id = writer2_id;

end $$;

-- ----------------------------------------------------------------------------
-- 15. Seed 60 published articles (10 per category)
-- ----------------------------------------------------------------------------
do $$
declare
  cat_id uuid;
  auth_id uuid;
begin
  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Inside the market union''s quiet fight over bus park control',
    'inside-the-market-union-s-quiet-fight-over-bus-park-control-01',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1032,
    51,
    now() - interval '41 days',
    now() - interval '41 days',
    now() - interval '41 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why the new fuel subsidy rollback is splitting local traders',
    'why-the-new-fuel-subsidy-rollback-is-splitting-local-traders-02',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4587,
    229,
    now() - interval '7 days',
    now() - interval '7 days',
    now() - interval '7 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'State assembly quietly shelves the transport reform bill',
    'state-assembly-quietly-shelves-the-transport-reform-bill-03',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1911,
    95,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Ward-level voter registration numbers are down — here''s why',
    'ward-level-voter-registration-numbers-are-down---here-s-why-04',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    4584,
    229,
    now() - interval '13 days',
    now() - interval '13 days',
    now() - interval '13 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The community town-hall that turned into a shouting match',
    'the-community-town-hall-that-turned-into-a-shouting-match-05',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1427,
    71,
    now() - interval '1 days',
    now() - interval '1 days',
    now() - interval '1 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Local government elections: who''s actually on the ballot',
    'local-government-elections--who-s-actually-on-the-ballot-06',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    957,
    47,
    now() - interval '22 days',
    now() - interval '22 days',
    now() - interval '22 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A council seat, three candidates, and one contested register',
    'a-council-seat--three-candidates--and-one-contested-register-07',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    2286,
    114,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why the new market levy is dividing shop owners',
    'why-the-new-market-levy-is-dividing-shop-owners-08',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    4642,
    232,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The road contract nobody can find the paperwork for',
    'the-road-contract-nobody-can-find-the-paperwork-for-09',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    495,
    24,
    now() - interval '5 days',
    now() - interval '5 days',
    now() - interval '5 days'
  );

  select id into cat_id from categories where slug = 'politics';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'What the new zoning rules mean for street vendors',
    'what-the-new-zoning-rules-mean-for-street-vendors-10',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    2397,
    119,
    now() - interval '25 days',
    now() - interval '25 days',
    now() - interval '25 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The Afrobeats producers building studios in shipping containers',
    'the-afrobeats-producers-building-studios-in-shipping-contain-11',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    2307,
    115,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why local theatre is having a quiet resurgence downtown',
    'why-local-theatre-is-having-a-quiet-resurgence-downtown-12',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3906,
    195,
    now() - interval '11 days',
    now() - interval '11 days',
    now() - interval '11 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Inside the community mural project reclaiming an underpass',
    'inside-the-community-mural-project-reclaiming-an-underpass-13',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1996,
    99,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The vinyl shop that outlasted three shopping malls',
    'the-vinyl-shop-that-outlasted-three-shopping-malls-14',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    4766,
    238,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A weekend guide to the neighborhood''s smallest galleries',
    'a-weekend-guide-to-the-neighborhood-s-smallest-galleries-15',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    2289,
    114,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'How a church choir became a Sunday-night open mic',
    'how-a-church-choir-became-a-sunday-night-open-mic-16',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3629,
    181,
    now() - interval '38 days',
    now() - interval '38 days',
    now() - interval '38 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The tailor stitching three generations of wedding gowns',
    'the-tailor-stitching-three-generations-of-wedding-gowns-17',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    864,
    43,
    now() - interval '32 days',
    now() - interval '32 days',
    now() - interval '32 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Street food vendors are the city''s real food critics',
    'street-food-vendors-are-the-city-s-real-food-critics-18',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    640,
    32,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The book club that only reads what its members write',
    'the-book-club-that-only-reads-what-its-members-write-19',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4652,
    232,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );

  select id into cat_id from categories where slug = 'culture';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why everyone under 25 is suddenly learning highlife guitar',
    'why-everyone-under-25-is-suddenly-learning-highlife-guitar-20',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    2524,
    126,
    now() - interval '8 days',
    now() - interval '8 days',
    now() - interval '8 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Naira stabilizes, but street traders say prices haven''t followed',
    'naira-stabilizes--but-street-traders-say-prices-haven-t-foll-21',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1583,
    79,
    now() - interval '33 days',
    now() - interval '33 days',
    now() - interval '33 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The thrift market outgrowing its own square footage',
    'the-thrift-market-outgrowing-its-own-square-footage-22',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3183,
    159,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Small importers are quietly rerouting around the port backlog',
    'small-importers-are-quietly-rerouting-around-the-port-backlo-23',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. What''s changed this time, several sources agreed, is that people are finally documenting it as it happens. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4122,
    206,
    now() - interval '21 days',
    now() - interval '21 days',
    now() - interval '21 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A co-op of seamstresses just landed their first export order',
    'a-co-op-of-seamstresses-just-landed-their-first-export-order-24',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    2093,
    104,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why three fintech apps launched in this city in one month',
    'why-three-fintech-apps-launched-in-this-city-in-one-month-25',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1171,
    58,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The generator-rental business booming on unreliable power',
    'the-generator-rental-business-booming-on-unreliable-power-26',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3586,
    179,
    now() - interval '39 days',
    now() - interval '39 days',
    now() - interval '39 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Local bakeries are feeling a flour price squeeze',
    'local-bakeries-are-feeling-a-flour-price-squeeze-27',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3179,
    158,
    now() - interval '43 days',
    now() - interval '43 days',
    now() - interval '43 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Motorcycle taxi apps are quietly rewriting commute times',
    'motorcycle-taxi-apps-are-quietly-rewriting-commute-times-28',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    644,
    32,
    now() - interval '15 days',
    now() - interval '15 days',
    now() - interval '15 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The barbershop chain scaling one franchise at a time',
    'the-barbershop-chain-scaling-one-franchise-at-a-time-29',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1924,
    96,
    now() - interval '38 days',
    now() - interval '38 days',
    now() - interval '38 days'
  );

  select id into cat_id from categories where slug = 'business';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why so many graduates are choosing trade over tech this year',
    'why-so-many-graduates-are-choosing-trade-over-tech-this-year-30',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    2826,
    141,
    now() - interval '3 days',
    now() - interval '3 days',
    now() - interval '3 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'MIVA students push back on the new exam-fee structure',
    'miva-students-push-back-on-the-new-exam-fee-structure-31',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4537,
    226,
    now() - interval '14 days',
    now() - interval '14 days',
    now() - interval '14 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The unofficial guide to surviving TMA season',
    'the-unofficial-guide-to-surviving-tma-season-32',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3454,
    172,
    now() - interval '31 days',
    now() - interval '31 days',
    now() - interval '31 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Inside the dorm-room startup pitching to real investors',
    'inside-the-dorm-room-startup-pitching-to-real-investors-33',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3487,
    174,
    now() - interval '28 days',
    now() - interval '28 days',
    now() - interval '28 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why the library''s new booking system is causing chaos',
    'why-the-library-s-new-booking-system-is-causing-chaos-34',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    1015,
    50,
    now() - interval '22 days',
    now() - interval '22 days',
    now() - interval '22 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A professor''s side project just got picked up nationally',
    'a-professor-s-side-project-just-got-picked-up-nationally-35',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3576,
    178,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The student union election nobody saw coming',
    'the-student-union-election-nobody-saw-coming-36',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4628,
    231,
    now() - interval '29 days',
    now() - interval '29 days',
    now() - interval '29 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Campus wifi outages are now a running joke — and a real problem',
    'campus-wifi-outages-are-now-a-running-joke---and-a-real-prob-37',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1482,
    74,
    now() - interval '16 days',
    now() - interval '16 days',
    now() - interval '16 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'How one cohort turned a group chat into a tutoring network',
    'how-one-cohort-turned-a-group-chat-into-a-tutoring-network-38',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1468,
    73,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The scholarship fund started by three final-year students',
    'the-scholarship-fund-started-by-three-final-year-students-39',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3585,
    179,
    now() - interval '19 days',
    now() - interval '19 days',
    now() - interval '19 days'
  );

  select id into cat_id from categories where slug = 'campus';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why more students are commuting instead of relocating',
    'why-more-students-are-commuting-instead-of-relocating-40',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4864,
    243,
    now() - interval '4 days',
    now() - interval '4 days',
    now() - interval '4 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'We keep calling it ''gist'' — maybe that''s the point',
    'we-keep-calling-it--gist----maybe-that-s-the-point-41',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>We''ll have more once officials are ready to speak on the record. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4239,
    211,
    now() - interval '31 days',
    now() - interval '31 days',
    now() - interval '31 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Stop treating comment sections as an afterthought',
    'stop-treating-comment-sections-as-an-afterthought-42',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4994,
    249,
    now() - interval '5 days',
    now() - interval '5 days',
    now() - interval '5 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The quiet dignity of a well-run market stall',
    'the-quiet-dignity-of-a-well-run-market-stall-43',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. For weeks, the only real update came from word of mouth rather than any formal announcement. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>More than one person pointed out that this has been quietly brewing for far longer than most outsiders realized. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4862,
    243,
    now() - interval '16 days',
    now() - interval '16 days',
    now() - interval '16 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why local news still matters more than the national cycle',
    'why-local-news-still-matters-more-than-the-national-cycle-44',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    4402,
    220,
    now() - interval '37 days',
    now() - interval '37 days',
    now() - interval '37 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'In defense of the long, boring council meeting',
    'in-defense-of-the-long--boring-council-meeting-45',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>Even supporters of the current approach admit the communication around it could have gone better. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3362,
    168,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'What we lose when every corner store becomes a chain',
    'what-we-lose-when-every-corner-store-becomes-a-chain-46',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3874,
    193,
    now() - interval '1 days',
    now() - interval '1 days',
    now() - interval '1 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The case for reading the whole article, not just the headline',
    'the-case-for-reading-the-whole-article--not-just-the-headlin-47',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1205,
    60,
    now() - interval '17 days',
    now() - interval '17 days',
    now() - interval '17 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why ''small'' stories are usually the important ones',
    'why--small--stories-are-usually-the-important-ones-48',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>This isn''t the first attempt to address it, but it may be the first with any real momentum behind it. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>As always, we want to hear from anyone closer to this than we are. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    3709,
    185,
    now() - interval '11 days',
    now() - interval '11 days',
    now() - interval '11 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'On writing about your own neighborhood without flattering it',
    'on-writing-about-your-own-neighborhood-without-flattering-it-49',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. The first sign something had changed was how quiet the usual meeting spot suddenly became. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>As always, we want to hear from anyone closer to this than we are. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    968,
    48,
    now() - interval '20 days',
    now() - interval '20 days',
    now() - interval '20 days'
  );

  select id into cat_id from categories where slug = 'opinion';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The comment I almost didn''t approve — and why I did',
    'the-comment-i-almost-didn-t-approve---and-why-i-did-50',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    2351,
    117,
    now() - interval '10 days',
    now() - interval '10 days',
    now() - interval '10 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The five-a-side league quietly producing real talent',
    'the-five-a-side-league-quietly-producing-real-talent-51',
    '<p>For weeks, the only real update came from word of mouth rather than any formal announcement. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>The Gist will keep following this as it develops. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    5315,
    265,
    now() - interval '44 days',
    now() - interval '44 days',
    now() - interval '44 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why the community stadium renovation keeps stalling',
    'why-the-community-stadium-renovation-keeps-stalling-52',
    '<p>The first sign something had changed was how quiet the usual meeting spot suddenly became. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Several long-time residents say they''ve seen versions of this play out before, just never quite at this scale. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    5316,
    265,
    now() - interval '6 days',
    now() - interval '6 days',
    now() - interval '6 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A referee''s-eye view of the derby everyone''s still talking about',
    'a-referee-s-eye-view-of-the-derby-everyone-s-still-talking-a-53',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>It''s a small story with a much bigger question sitting underneath it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    5339,
    266,
    now() - interval '9 days',
    now() - interval '9 days',
    now() - interval '9 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The women''s league finally getting a real broadcast deal',
    'the-women-s-league-finally-getting-a-real-broadcast-deal-54',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The disagreement, at its core, seems to be less about the goal and more about who gets to decide how to reach it. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>The Gist will keep following this as it develops. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    199,
    9,
    now() - interval '36 days',
    now() - interval '36 days',
    now() - interval '36 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Inside the boxing gym training champions before breakfast',
    'inside-the-boxing-gym-training-champions-before-breakfast-55',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. It began with a single post that a handful of neighbors shared before anyone official weighed in. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>For now, the story remains open, and so does the conversation around it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    4891,
    244,
    now() - interval '24 days',
    now() - interval '24 days',
    now() - interval '24 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why grassroots scouts are showing up to primary school matches',
    'why-grassroots-scouts-are-showing-up-to-primary-school-match-56',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>For now, the story remains open, and so does the conversation around it. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    446,
    22,
    now() - interval '24 days',
    now() - interval '24 days',
    now() - interval '24 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The rivalry that started over a parking dispute, not football',
    'the-rivalry-that-started-over-a-parking-dispute--not-footbal-57',
    '<p>It started, as these things often do, with a complaint nobody expected to go anywhere. Nobody involved expected this to still be unresolved months later, but here we are. By the time the dust settled, the story had grown into something the whole neighborhood was talking about.</p><p>What makes this worth following isn''t the headline moment — it''s everything underneath it. The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Residents who spoke to The Gist described a slow build-up of frustration that finally reached a breaking point, though few could agree on exactly when that was.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. Officials contacted for this piece either declined to comment or didn''t respond by publication time, which itself has become a familiar part of how these stories tend to unfold locally.</p><p>It''s a small story with a much bigger question sitting underneath it. Whatever happens next, it''s clear the people closest to it aren''t done talking about it.</p>',
    'published', auth_id, cat_id,
    3449,
    172,
    now() - interval '36 days',
    now() - interval '36 days',
    now() - interval '36 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'tari.amadi@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'A coach''s 20-year unpaid project just got its first sponsor',
    'a-coach-s-20-year-unpaid-project-just-got-its-first-sponsor-58',
    '<p>It began with a single post that a handful of neighbors shared before anyone official weighed in. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>Even supporters of the current approach admit the communication around it could have gone better. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1589,
    79,
    now() - interval '2 days',
    now() - interval '2 days',
    now() - interval '2 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'chuka.eze@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'The marathon route locals actually recommend running',
    'the-marathon-route-locals-actually-recommend-running-59',
    '<p>A routine meeting turned into hours of back-and-forth once the numbers were finally put on the table. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>Numbers alone don''t capture it — the mood on the ground has shifted in a way that''s hard to quantify. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>The paper trail, where one exists at all, tells a noticeably different story than the public statements so far. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    1005,
    50,
    now() - interval '45 days',
    now() - interval '45 days',
    now() - interval '45 days'
  );

  select id into cat_id from categories where slug = 'sports';
  select id into auth_id from profiles where email = 'ada.chukwu@seed.thegist.demo';
  insert into articles (title, slug, body, status, author_id, category_id, read_count, like_count, published_at, created_at, updated_at)
  values (
    'Why ticket prices at the local derby just doubled',
    'why-ticket-prices-at-the-local-derby-just-doubled-60',
    '<p>Nobody involved expected this to still be unresolved months later, but here we are. That''s the plain version of it, at least. The fuller picture, gathered over several conversations this month, is a little more complicated.</p><p>The people most affected are, unsurprisingly, the ones who''ve had the least say in how it''s handled. Several people directly involved described the situation in strikingly similar terms, even though none of them had spoken to each other beforehand.</p><p>A few of those closest to the situation asked not to be named, citing concerns about how it might be received. It''s the kind of detail that rarely makes it into an official statement, but that locals say matters more than the headline figures.</p><p>We''ll have more once officials are ready to speak on the record. For now, most of the people we spoke with say they''re watching closely — and expecting more updates before this is truly settled.</p>',
    'published', auth_id, cat_id,
    2984,
    149,
    now() - interval '30 days',
    now() - interval '30 days',
    now() - interval '30 days'
  );

end $$;
