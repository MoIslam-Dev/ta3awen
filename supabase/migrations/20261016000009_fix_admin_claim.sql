-- Fix: admins could not reserve ("حجز") a listing.
--
-- listings_guard() (0006) returned from an admin fast-path *before* the claim
-- branch ran, so an admin reserving a listing left claimed_by set with
-- claimed_at still null. The listings_claim_shape check constraint requires the
-- claim to be all-or-nothing, so the write failed with:
--   new row for relation "listings" violates check constraint
--   "listings_claim_shape"  (SQLSTATE 23514)
-- Regular users were unaffected because the claim branch sets claimed_at.
--
-- Keep the admin fast-path (admins may edit any listing) but normalise the
-- claim shape before returning.
create or replace function public.listings_guard()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  new.owner_id   := old.owner_id;    -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

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
