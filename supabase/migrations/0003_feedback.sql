-- ============================================================================
-- 0003 — Feedback
-- Run this AFTER 0002_security_hardening.sql.
-- ============================================================================

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

alter table feedback enable row level security;

-- Anyone (including logged-out visitors) can submit feedback.
create policy "Anyone can submit feedback"
  on feedback for insert with check (true);

-- Only editors can read submitted feedback.
create policy "Editors read feedback"
  on feedback for select using (public.current_role() = 'editor');

create policy "Editors update feedback status"
  on feedback for update using (public.current_role() = 'editor');

-- New tables don't inherit the grants from 0002 automatically — grant this
-- one explicitly, and set a default so future tables in this schema do.
grant select, insert, update, delete on feedback to anon, authenticated;
alter default privileges in schema public
  grant select, insert, update, delete on tables to anon, authenticated;
