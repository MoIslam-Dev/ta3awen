-- Ta3awen — helpers, lifecycle guards and admin RPCs.
--
-- Authorization has two layers:
--   1. RLS (0003) decides WHICH rows a user may touch.
--   2. These triggers decide WHICH transitions/fields are legal — they mirror
--      the state machines that used to live in firestore.rules.

-- ---------------------------------------------------------------------------
-- helpers
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from public.admins a where a.user_id = auth.uid());
$$;

create or replace function public.is_disabled()
returns boolean
language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce((select p.disabled from public.profiles p where p.id = auth.uid()), false);
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- profiles: owners may only change the editable columns
-- ---------------------------------------------------------------------------
create or replace function public.profiles_guard()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if public.is_admin() then
    return new;
  end if;
  -- freeze everything except full_name / wilaya / commune / contact_phone
  new.id              := old.id;
  new.email           := old.email;
  new.disabled        := old.disabled;
  new.disabled_reason := old.disabled_reason;
  new.post_count      := old.post_count;
  new.created_at      := old.created_at;
  return new;
end $$;

create trigger profiles_guard_trg
  before update on public.profiles
  for each row execute function public.profiles_guard();

-- ---------------------------------------------------------------------------
-- anti-spam: lifetime post cap, enforced server-side (was client-maintained)
-- ---------------------------------------------------------------------------
create or replace function public.bump_post_count()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare n integer;
begin
  if public.is_disabled() then
    raise exception 'account disabled' using errcode = '42501';
  end if;
  update public.profiles
     set post_count = post_count + 1
   where id = auth.uid() and post_count < 100
   returning post_count into n;
  if n is null then
    raise exception 'post limit reached' using errcode = '42501';
  end if;
  return new;
end $$;

create trigger listings_post_count_trg
  before insert on public.listings
  for each row execute function public.bump_post_count();

create trigger requests_post_count_trg
  before insert on public.requests
  for each row execute function public.bump_post_count();

-- ---------------------------------------------------------------------------
-- listings state machine:
--   متاح --claim--> محجوز --owner confirms--> تم التبرع به
--   محجوز --cancel--> متاح   |   owner may also flip متاح <-> تم التبرع به
-- ---------------------------------------------------------------------------
create or replace function public.listings_guard()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  new.owner_id   := old.owner_id;    -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

  if public.is_admin() then
    return new;
  end if;

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

create trigger listings_guard_trg
  before update on public.listings
  for each row execute function public.listings_guard();

-- ---------------------------------------------------------------------------
-- requests state machine:
--   open --match--> matched --release(matcher/author)--> open | --author--> closed
--   open <-> closed (author toggle)
-- ---------------------------------------------------------------------------
create or replace function public.requests_guard()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  new.uid        := old.uid;         -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

  if public.is_admin() then
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

create trigger requests_guard_trg
  before update on public.requests
  for each row execute function public.requests_guard();

-- ---------------------------------------------------------------------------
-- admin RPCs (all guard on is_admin(); SECURITY DEFINER bypasses RLS)
-- ---------------------------------------------------------------------------
create or replace function public.set_admin(target uuid, value boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;
  if value then
    insert into public.admins (user_id) values (target) on conflict do nothing;
  else
    delete from public.admins where user_id = target;
  end if;
end $$;

create or replace function public.set_user_disabled(target uuid, value boolean, reason text default null)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;
  update public.profiles
     set disabled = value,
         disabled_reason = case when value then reason else null end
   where id = target;
end $$;

create or replace function public.resolve_report(target uuid, new_status text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;
  if new_status not in ('open', 'resolved', 'dismissed') then
    raise exception 'bad report status' using errcode = '22000';
  end if;
  update public.reports
     set status = new_status,
         resolved_at = case when new_status = 'open' then null else now() end
   where id = target;
end $$;

-- Deletes a listing, its image rows and any reports targeting it.
create or replace function public.delete_listing(target uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not (public.is_admin() or exists (
        select 1 from public.listings where id = target and owner_id = auth.uid())) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  delete from public.listings where id = target;  -- images/reports cascade/set-null
end $$;

create or replace function public.delete_request(target uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not (public.is_admin() or exists (
        select 1 from public.requests where id = target and uid = auth.uid())) then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  delete from public.requests where id = target;
end $$;

-- Removes all application data for a user (auth.users deletion is a separate
-- administrative step via the service role / Admin API).
create or replace function public.delete_user_data(target uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if not public.is_admin() then
    raise exception 'not an admin' using errcode = '42501';
  end if;
  delete from public.listings where owner_id = target;
  delete from public.requests where uid = target;
  delete from public.reports  where reporter_id = target;
  delete from public.admins   where user_id = target;
  delete from public.profiles where id = target;
end $$;
