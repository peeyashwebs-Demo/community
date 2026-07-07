-- ============================================================================
-- 0007 — Fix: "signed up as writer, still shows as reader"
--
-- Root cause: the signup page called supabase.auth.signUp(), then tried to
-- UPDATE the new profile's role client-side. But if email confirmation is
-- on (the Supabase default), signUp() doesn't return an active session —
-- so that follow-up update ran with no logged-in user, RLS silently blocked
-- it, and the role stayed 'reader'.
--
-- Fix: the requested role now rides inside the signup call's own metadata
-- (raw_user_meta_data), and this trigger — which runs as part of the same
-- database transaction that creates the user, with no RLS involved at all —
-- reads it directly. No dependency on having an active session afterward.
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger as $$
declare
  requested text := new.raw_user_meta_data->>'requested_role';
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    -- Only 'writer' can be requested at signup — 'editor' is never
    -- honored here, no matter what a client sends.
    case when requested = 'writer' then 'writer'::user_role else 'reader'::user_role end
  );
  return new;
end;
$$ language plpgsql security definer;
