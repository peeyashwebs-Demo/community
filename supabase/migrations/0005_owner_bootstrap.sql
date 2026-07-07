-- ============================================================================
-- 0005 — Owner bootstrap
-- Run this AFTER 0004_seed_articles.sql.
--
-- Problem this solves: editor accounts are intentionally not self-service
-- (see 0002's prevent_role_escalation trigger) — but *someone* has to become
-- the first editor. This function allows exactly that, exactly once: it only
-- succeeds if there are zero editors anywhere in the system yet. After the
-- very first editor claims the role, this permanently stops working for
-- everyone else, including the same caller if they somehow lost the role.
-- ============================================================================

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
