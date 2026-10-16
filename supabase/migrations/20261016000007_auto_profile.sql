-- Ta3awen — guarantee an email/password account always has a profile row.
--
-- Why this migration exists:
-- The anti-spam trigger `bump_post_count` updates `profiles` on every listing /
-- request insert and raises errcode 42501 when there is no row to update. The
-- app maps 42501 to "permission denied", so an account whose profile insert
-- failed (e.g. a dropped request right after sign-up) could not publish
-- anything and saw a misleading permission error.
--
-- Standard Supabase remedy: seed the profile from the auth trigger. It is
-- scoped to `provider = 'email'` on purpose: Google first sign-ins must keep
-- flowing through the in-app completion screen (name + wilaya + commune), so
-- we must NOT create an empty profile for them.
--
-- The client still upserts the profile right after register(); the trigger is
-- a safety net so a profile row exists no matter what the client does.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  provider text := coalesce(new.raw_app_meta_data->>'provider', 'email');
begin
  if provider = 'email' then
    insert into public.profiles (id, full_name, email)
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
        nullif(trim(new.raw_user_meta_data->>'name'), ''),
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        'مستخدم'
      ),
      coalesce(new.email, '')
    )
    on conflict (id) do nothing;
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
