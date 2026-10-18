-- Ta3awen — reservation/match lifecycle hygiene (expiry + anti-hoarding).
--
-- Problem this solves: a single reservation (listing) or match (board/blood
-- post) removes the item from everyone else's feed and, without a clock, can
-- stay there forever. And nothing stopped one user from hoarding many items.
--
-- Design (all server-side, so the client does zero extra reads):
-- * `app_config` holds the tunable policy (TTLs + per-user cap) so we can tune
--   behaviour without shipping an app update or re-deploying.
-- * `expire_stale_reservations()` is run by pg_cron every 15 min. It reopens
--   stale reservations/matches and notifies only the person whose hold lapsed.
--   A shorter clock is used for blood, which is time-critical.
-- * Both guard functions gained (a) a transaction-local "system" bypass so the
--   maintenance function may legitimately reopen rows it does not own, and
--   (b) a concurrent-reservation cap for listings.
-- * Partial indexes keep the expiry scan and the per-user count cheap.
--
-- The client is unchanged: it still reads `status = 'متاح'` / `status = 'open'`,
-- so the extra reads live entirely in the database and never hit the client.

-- ---------------------------------------------------------------------------
-- policy configuration (tunable, not exposed to clients)
-- ---------------------------------------------------------------------------
create table if not exists public.app_config (
  key         text primary key,
  int_value   integer not null,
  description text not null default ''
);

insert into public.app_config (key, int_value, description) values
  ('listing_claim_ttl_hours',    48, 'Hours before an unconfirmed listing reservation auto-releases'),
  ('request_match_ttl_hours',    72, 'Hours before an unconfirmed general non-blood match expires'),
  ('blood_match_ttl_hours',      12, 'Hours before an unconfirmed blood match expires (time-critical)'),
  ('max_active_listing_claims',   3, 'Max concurrent active reservations a user may hold (0 = unlimited)')
on conflict (key) do nothing;

alter table public.app_config enable row level security;
revoke all on public.app_config from anon, authenticated;
grant select, insert, update, delete on public.app_config to service_role;

create or replace function public.config_int(p_key text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((select int_value from public.app_config where key = p_key), p_default);
$$;

revoke execute on function public.config_int(text, integer) from public, anon, authenticated;
grant execute on function public.config_int(text, integer) to service_role;

-- ---------------------------------------------------------------------------
-- cheap indexes for the job + the per-user cap
-- ---------------------------------------------------------------------------
create index if not exists listings_claim_active_idx
  on public.listings (claimed_by) where status = 'محجوز';
create index if not exists listings_claim_expiry_idx
  on public.listings (claimed_at) where status = 'محجوز';
create index if not exists requests_match_active_idx
  on public.requests (matched_by) where status = 'matched';
create index if not exists requests_match_expiry_idx
  on public.requests (matched_at) where status = 'matched';

-- ---------------------------------------------------------------------------
-- notification types: add the two "expired" kinds
-- ---------------------------------------------------------------------------
alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in (
    'listing_claimed', 'listing_released', 'listing_given',
    'request_matched', 'blood_matched',
    'request_released', 'request_closed', 'report_new',
    'listing_expired', 'request_expired'));

-- ---------------------------------------------------------------------------
-- listings guard: system bypass + concurrent-reservation cap
-- ---------------------------------------------------------------------------
create or replace function public.listings_guard()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid   uuid := auth.uid();
  v_max int;
begin
  new.owner_id   := old.owner_id;    -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

  -- System path: a transaction-local flag set only by our SECURITY DEFINER
  -- maintenance functions (e.g. the expiry job). Clients can never set it.
  if current_setting('ta3awen.system', true) = 'on' then
    if new.claimed_by is null then
      new.claimed_at := null;
    end if;
    return new;
  end if;

  if public.is_admin() then
    -- A claim is all-or-nothing: if a claimant is present but no timestamp was
    -- supplied, stamp it now; if there is no claimant, clear the timestamp.
    if new.claimed_by is not null and new.claimed_at is null then
      new.claimed_at := now();
    elsif new.claimed_by is null then
      new.claimed_at := null;
    end if;
    return new;
  end if;

  new.is_demo := old.is_demo;        -- only admins may toggle the demo flag

  if new.status = old.status then
    -- content edit: owner only, claim fields untouched
    if uid <> old.owner_id then
      raise exception 'only the owner may edit this listing' using errcode = '42501';
    end if;
    if new.claimed_by is distinct from old.claimed_by
       or new.claimed_by_name is distinct from old.claimed_by_name
       or new.claimed_at is distinct from old.claimed_at then
      raise exception 'claim fields cannot be edited directly' using errcode = '42501';
    end if;

  elsif old.status = 'متاح' and new.status = 'محجوز' then
    -- claim by a non-owner
    if uid = old.owner_id then
      raise exception 'cannot reserve your own listing' using errcode = '42501';
    end if;
    if public.is_disabled() then
      raise exception 'account disabled' using errcode = '42501';
    end if;
    if new.claimed_by_name is null or char_length(new.claimed_by_name) = 0 then
      raise exception 'claimed_by_name required' using errcode = '22000';
    end if;

    -- anti-hoarding: cap concurrent active reservations per user
    v_max := public.config_int('max_active_listing_claims', 3);
    if v_max > 0 and (
      select count(*) from public.listings
       where claimed_by = uid and status = 'محجوز'
    ) >= v_max then
      raise exception 'too many active reservations (max %)', v_max using errcode = '54000';
    end if;

    new.claimed_by := uid;
    new.claimed_at := now();

  elsif old.status = 'محجوز' and new.status = 'متاح' then
    if not (uid = old.owner_id or uid = old.claimed_by) then
      raise exception 'only owner or claimant may release' using errcode = '42501';
    end if;
    new.claimed_by := null;
    new.claimed_by_name := null;
    new.claimed_at := null;

  elsif old.status = 'محجوز' and new.status = 'تم التبرع به' then
    if uid <> old.owner_id then
      raise exception 'only the owner may confirm delivery' using errcode = '42501';
    end if;

  elsif old.status = 'متاح' and new.status = 'تم التبرع به' then
    if uid <> old.owner_id then
      raise exception 'only the owner may mark as given' using errcode = '42501';
    end if;

  elsif old.status = 'تم التبرع به' and new.status = 'متاح' then
    if uid <> old.owner_id then
      raise exception 'only the owner may reopen' using errcode = '42501';
    end if;

  else
    raise exception 'invalid listing status transition % -> %', old.status, new.status
      using errcode = '22000';
  end if;

  return new;
end $$;

-- ---------------------------------------------------------------------------
-- requests guard: system bypass
-- ---------------------------------------------------------------------------
create or replace function public.requests_guard()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare uid uuid := auth.uid();
begin
  new.uid        := old.uid;         -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

  -- System path: see listings_guard.
  if current_setting('ta3awen.system', true) = 'on' then
    if new.matched_by is null then
      new.matched_at := null;
    end if;
    return new;
  end if;

  if public.is_admin() then
    -- A match is all-or-nothing: if a matcher is present but no timestamp was
    -- supplied, stamp it now; if there is no matcher, clear the timestamp.
    if new.matched_by is not null and new.matched_at is null then
      new.matched_at := now();
    elsif new.matched_by is null then
      new.matched_at := null;
    end if;
    return new;
  end if;

  if new.status = old.status then
    -- content edit: author only; kind and match keys immutable
    if uid <> old.uid then
      raise exception 'only the author may edit this post' using errcode = '42501';
    end if;
    if new.kind is distinct from old.kind then
      raise exception 'kind cannot be changed' using errcode = '22000';
    end if;
    if new.matched_by is distinct from old.matched_by
       or new.matched_name is distinct from old.matched_name
       or new.matched_at is distinct from old.matched_at then
      raise exception 'match fields cannot be edited directly' using errcode = '42501';
    end if;

  elsif old.status = 'open' and new.status = 'matched' then
    if uid = old.uid then
      raise exception 'cannot match your own post' using errcode = '42501';
    end if;
    if public.is_disabled() then
      raise exception 'account disabled' using errcode = '42501';
    end if;
    if new.matched_name is null or char_length(new.matched_name) = 0 then
      raise exception 'matched_name required' using errcode = '22000';
    end if;
    new.matched_by := uid;
    new.matched_at := now();

  elsif old.status = 'matched' and new.status in ('open', 'closed') then
    if new.status = 'open' and not (uid = old.uid or uid = old.matched_by) then
      raise exception 'only author or matcher may release' using errcode = '42501';
    end if;
    if new.status = 'closed' and uid <> old.uid then
      raise exception 'only the author may finalize' using errcode = '42501';
    end if;
    new.matched_by := null;
    new.matched_name := null;
    new.matched_at := null;

  elsif old.status = 'open' and new.status = 'closed' then
    if uid <> old.uid then
      raise exception 'only the author may close' using errcode = '42501';
    end if;

  elsif old.status = 'closed' and new.status = 'open' then
    if uid <> old.uid then
      raise exception 'only the author may reopen' using errcode = '42501';
    end if;

  else
    raise exception 'invalid request status transition % -> %', old.status, new.status
      using errcode = '22000';
  end if;

  return new;
end $$;

-- ---------------------------------------------------------------------------
-- notify functions: stay silent on the system path (the job emits its own,
-- correctly-worded notifications instead of a misleading "released" message).
-- ---------------------------------------------------------------------------
create or replace function public.notify_listing_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if current_setting('ta3awen.system', true) = 'on' then
    return null;
  end if;

  if old.status = 'متاح' and new.status = 'محجوز' then
    insert into public.notifications (user_id, type, actor_name, listing_id)
    values (new.owner_id, 'listing_claimed', coalesce(new.claimed_by_name, ''),
            new.id);

  elsif old.status = 'محجوز' and new.status = 'متاح' then
    -- only worth telling the owner when the *claimant* released it
    if old.claimed_by is not null and old.claimed_by <> new.owner_id then
      insert into public.notifications (user_id, type, actor_name, listing_id)
      values (new.owner_id, 'listing_released', coalesce(old.claimed_by_name, ''),
              new.id);
    end if;

  elsif old.status <> 'تم التبرع به' and new.status = 'تم التبرع به' then
    if new.claimed_by is not null then
      -- recipient is the claimant; the actor is the owner who confirmed
      insert into public.notifications (user_id, type, actor_name, listing_id)
      values (new.claimed_by, 'listing_given', coalesce(new.owner_name, ''),
              new.id);
    end if;
  end if;

  return null;
end $$;

create or replace function public.notify_request_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if current_setting('ta3awen.system', true) = 'on' then
    return null;
  end if;

  if old.status = 'open' and new.status = 'matched' then
    insert into public.notifications (user_id, type, actor_name, request_id)
    values (new.uid,
            case when new.kind = 'blood' then 'blood_matched'
                 else 'request_matched' end,
            coalesce(new.matched_name, ''), new.id);

  elsif old.status = 'matched' and new.status = 'open' then
    if old.matched_by is not null then
      insert into public.notifications (user_id, type, actor_name, request_id)
      values (new.uid, 'request_released', coalesce(old.matched_name, ''),
              new.id);
    end if;

  elsif old.status = 'matched' and new.status = 'closed' then
    if old.matched_by is not null then
      -- recipient is the matcher; the actor is the post author who closed it
      insert into public.notifications (user_id, type, actor_name, request_id)
      values (old.matched_by, 'request_closed', coalesce(new.user_name, ''),
              new.id);
    end if;
  end if;

  return null;
end $$;

-- ---------------------------------------------------------------------------
-- the maintenance function (run by pg_cron; not callable by clients)
-- ---------------------------------------------------------------------------
create or replace function public.expire_stale_reservations()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_list  int;
  v_blood int;
  v_req   int;
  v_ttl_listing interval := make_interval(hours => public.config_int('listing_claim_ttl_hours', 48));
  v_ttl_request interval := make_interval(hours => public.config_int('request_match_ttl_hours', 72));
  v_ttl_blood   interval := make_interval(hours => public.config_int('blood_match_ttl_hours', 12));
begin
  -- Mark this transaction as a trusted system change (see the guards).
  perform set_config('ta3awen.system', 'on', true);

  -- listings: notify the claimant, then reopen (single pass over the index)
  insert into public.notifications (user_id, type, actor_name, listing_id)
  select l.claimed_by, 'listing_expired', coalesce(l.claimed_by_name, ''), l.id
    from public.listings l
   where l.status = 'محجوز' and l.claimed_by is not null
     and l.claimed_at is not null and l.claimed_at < now() - v_ttl_listing;

  update public.listings
     set status = 'متاح', claimed_by = null, claimed_by_name = null, claimed_at = null
   where status = 'محجوز' and claimed_by is not null
     and claimed_at is not null and claimed_at < now() - v_ttl_listing;
  get diagnostics v_list = row_count;

  -- blood posts: shortest clock
  insert into public.notifications (user_id, type, actor_name, request_id)
  select r.matched_by, 'request_expired', coalesce(r.matched_name, ''), r.id
    from public.requests r
   where r.kind = 'blood' and r.status = 'matched' and r.matched_by is not null
     and r.matched_at is not null and r.matched_at < now() - v_ttl_blood;

  update public.requests
     set status = 'open', matched_by = null, matched_name = null, matched_at = null
   where kind = 'blood' and status = 'matched' and matched_by is not null
     and matched_at is not null and matched_at < now() - v_ttl_blood;
  get diagnostics v_blood = row_count;

  -- other board posts
  insert into public.notifications (user_id, type, actor_name, request_id)
  select r.matched_by, 'request_expired', coalesce(r.matched_name, ''), r.id
    from public.requests r
   where r.kind <> 'blood' and r.status = 'matched' and r.matched_by is not null
     and r.matched_at is not null and r.matched_at < now() - v_ttl_request;

  update public.requests
     set status = 'open', matched_by = null, matched_name = null, matched_at = null
   where kind <> 'blood' and status = 'matched' and matched_by is not null
     and matched_at is not null and matched_at < now() - v_ttl_request;
  get diagnostics v_req = row_count;

  return v_list + v_blood + v_req;
end $$;

revoke execute on function public.expire_stale_reservations() from public, anon, authenticated;
grant execute on function public.expire_stale_reservations() to service_role;

-- ---------------------------------------------------------------------------
-- schedule it every 15 minutes
-- ---------------------------------------------------------------------------
create extension if not exists pg_cron;

do $$
begin
  if not exists (select 1 from cron.job where jobname = 'ta3awen_expire_reservations') then
    perform cron.schedule(
      'ta3awen_expire_reservations',
      '*/15 * * * *',
      'select public.expire_stale_reservations();'
    );
  end if;
end $$;
