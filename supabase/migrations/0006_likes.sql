-- ============================================================================
-- 0006 — Likes
-- Run this AFTER 0005_owner_bootstrap.sql.
-- ============================================================================

alter table articles add column like_count integer not null default 0;

create table likes (
  article_id uuid not null references articles(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (article_id, user_id)
);

create index idx_likes_article on likes(article_id);

alter table likes enable row level security;

create policy "Likes are publicly readable"
  on likes for select using (true);

create policy "Signed-in active users can like"
  on likes for insert with check (
    auth.uid() = user_id
    and exists (select 1 from profiles p where p.id = auth.uid() and p.status = 'active')
  );

create policy "Users remove their own like"
  on likes for delete using (auth.uid() = user_id);

-- Atomic toggle: like if not already liked, unlike if already liked. Keeps
-- articles.like_count in sync in the same transaction, so the client never
-- has to do a read-then-write race against other likers.
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

-- Give existing seeded articles a believable starting like_count.
update articles set like_count = floor(read_count * (0.03 + random() * 0.05));
