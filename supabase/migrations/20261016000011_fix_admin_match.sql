-- Fix: admins could not match a request (board / blood).
--
-- The same defect 0009 fixed for listings also lived in requests_guard():
-- the admin fast-path returned *before* the match branch ran, so an admin
-- matching an open post left matched_by set with matched_at still null. The
-- requests_match_shape check constraint requires the match to be
-- all-or-nothing, so the write failed with:
--   new row for relation "requests" violates check constraint
--   "requests_match_shape"  (SQLSTATE 23514)
-- Regular users were unaffected because the match branch sets matched_at.
--
-- Keep the admin fast-path (admins may edit any post) but normalise the match
-- shape before returning.
create or replace function public.requests_guard()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare uid uuid := auth.uid();
begin
  new.uid        := old.uid;         -- immutable
  new.created_at := old.created_at;  -- immutable
  new.updated_at := now();

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
