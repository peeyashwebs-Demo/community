-- ============================================================================
-- 0002 — Security hardening
-- Run this AFTER 0001_init.sql.
-- ============================================================================

-- Explicit Data API grants (Supabase now requires these on newer projects —
-- RLS still controls *which rows*, this controls *whether the role can reach
-- the table at all*).
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;

-- ----------------------------------------------------------------------------
-- Prevent self-promotion: the existing "Users can update their own profile"
-- policy lets any signed-in user update their own row — including `role` and
-- `status` — since RLS alone can't restrict individual columns. This trigger
-- closes that gap: only an editor may change role or status; anyone else's
-- attempt to change those two columns is silently reverted to the prior value.
-- ----------------------------------------------------------------------------
create function public.prevent_role_escalation()
returns trigger as $$
begin
  -- Only enforced for requests coming through the API with a real user JWT
  -- (auth.uid() is null for direct SQL editor / superuser access, which is
  -- how seeding and admin scripts run).
  if auth.uid() is not null and public.current_role() <> 'editor' then
    -- The one self-service role change this product allows: applying to
    -- become a writer. Anything else — including any path to 'editor' — is
    -- reverted to whatever it was before this update.
    if not (old.role = 'reader' and new.role = 'writer') then
      new.role = old.role;
    end if;
    -- Never let a non-editor change status (e.g. un-suspend themselves).
    new.status = old.status;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_prevent_role_escalation
  before update on profiles
  for each row execute procedure public.prevent_role_escalation();
