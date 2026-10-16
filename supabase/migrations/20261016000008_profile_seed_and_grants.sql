-- Ta3awen — make profile seeding unconditional + restore service_role grants.
--
-- 0007 tried to seed a profile only for provider = 'email'. In practice
-- `raw_app_meta_data->>'provider'` is not populated yet when the AFTER INSERT
-- trigger runs, so the condition fell through and every account got a row.
-- That is actually the behaviour we want: the app's AuthGate treats a profile
-- as "not ready" until wilaya + commune are set, and routes such users to the
-- completion screen. So we make the trigger explicit and deterministic:
-- every new auth user gets a profile row (name from metadata/email, empty
-- location); the client (or the Google completion screen) fills it in.
--
-- Also: our RLS migration only granted privileges to `authenticated`, leaving
-- service_role without table grants. Re-grant it (anon stays revoked).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
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
  return new;
end $$;

-- trigger `on_auth_user_created` from 0007 already points at this function.

grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant all on all functions in schema public to service_role;
grant all on all routines in schema public to service_role;
