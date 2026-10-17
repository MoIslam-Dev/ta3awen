-- Ta3awen — OS push delivery (FCM) for the in-app inbox.
--
-- The inbox rows themselves are unchanged (see 20261016000010_notifications).
-- This migration only adds the *transport*: one row per device the user is
-- signed in on, plus an AFTER INSERT trigger that hands each fresh notification
-- to a Supabase Edge Function which calls Firebase Cloud Messaging.
--
-- Design:
-- * `device_tokens` maps an FCM registration token to its owner. A token is
--   unique to a device+app install, so it is the PRIMARY KEY: when another
--   account signs in on the same device the row is re-pointed at the new user.
-- * Registration goes through a SECURITY DEFINER RPC, not a table grant: the
--   client may only ever claim a token for *itself*, and re-pointing a token
--   that was left behind by a previous account is allowed without the client
--   needing (and being unable) to touch the other user's row.
-- * `locale` lets the server pick the ar/en/fr wording for the OS notification,
--   which must be built before the app can run (terminated state).
-- * Recipients may only read/delete their own rows; only the Edge Function
--   (service_role) reads across users.
-- * The trigger calls the function through pg_net and is a no-op until the
--   Vault secrets `push_webhook_url` / `push_webhook_secret` are set, so the
--   whole migration is safe to apply before the backend is wired up.

-- ---------------------------------------------------------------------------
-- table
-- ---------------------------------------------------------------------------
create table public.device_tokens (
  token      text primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  platform   text not null default 'android' check (platform in ('android', 'ios', 'web')),
  locale     text not null default 'ar' check (locale in ('ar', 'en', 'fr')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index device_tokens_user_idx on public.device_tokens (user_id);

-- ---------------------------------------------------------------------------
-- grants + RLS: a device may only read/remove the token(s) it owns.
-- ---------------------------------------------------------------------------
grant select, delete on public.device_tokens to authenticated;
grant all on public.device_tokens to service_role;

alter table public.device_tokens enable row level security;

create policy device_tokens_select on public.device_tokens
  for select to authenticated
  using (user_id = auth.uid());

create policy device_tokens_delete on public.device_tokens
  for delete to authenticated
  using (user_id = auth.uid());

-- keep `updated_at` honest so the server can prune stale installs later.
create or replace function public.device_tokens_touch()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end $$;

create trigger device_tokens_touch_trg
  before update on public.device_tokens
  for each row execute function public.device_tokens_touch();

-- ---------------------------------------------------------------------------
-- registration RPCs (INSERT/UPDATE are not granted on the table itself).
-- ---------------------------------------------------------------------------
create or replace function public.register_device_token(
  p_token text,
  p_platform text,
  p_locale text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_token is null or char_length(p_token) < 10 then
    raise exception 'invalid token' using errcode = '22023';
  end if;

  insert into public.device_tokens (token, user_id, platform, locale)
  values (
    p_token,
    uid,
    case when p_platform in ('android', 'ios', 'web') then p_platform else 'android' end,
    case when p_locale in ('ar', 'en', 'fr') then p_locale else 'ar' end
  )
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = excluded.platform,
        locale     = excluded.locale,
        updated_at = now();
end $$;

grant execute on function public.register_device_token(text, text, text) to authenticated;

create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.device_tokens
   where token = p_token and user_id = auth.uid();
$$;

grant execute on function public.unregister_device_token(text) to authenticated;

-- ---------------------------------------------------------------------------
-- push fan-out: AFTER INSERT on a notification, POST the row to the Edge
-- Function. pg_net queues the request and returns immediately (non-blocking),
-- so it never adds latency to the transaction that created the notification.
-- ---------------------------------------------------------------------------
create extension if not exists pg_net;

create or replace function public.notifications_send_push()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  endpoint text;
  secret   text;
begin
  select decrypted_secret into endpoint
    from vault.decrypted_secrets where name = 'push_webhook_url' limit 1;
  select decrypted_secret into secret
    from vault.decrypted_secrets where name = 'push_webhook_secret' limit 1;

  -- Not configured yet (or intentionally disabled): stay silent.
  if endpoint is null or secret is null then
    return new;
  end if;

  perform net.http_post(
    url     := endpoint,
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'x-push-secret', secret),
    body    := jsonb_build_object('record', to_jsonb(new))
  );
  return new;
end $$;

create trigger notifications_push_trg
  after insert on public.notifications
  for each row execute function public.notifications_send_push();
