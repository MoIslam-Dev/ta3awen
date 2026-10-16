-- Ta3awen — normalized search, demo flag and Realtime.
--
-- Why this migration exists:
-- * Search parity: the Flutter client normalizes queries with
--   `normalizeSearchText` (lowercase, tashkeel/tatweel stripped, alef/hamza/
--   teh-marbuta unified). The generated `search_text` columns in 0001 were only
--   `lower(...)`, so 'أَلْبِاب' would not match a query of 'الباب'. We now build
--   `search_text` with `normalize_ar()` so indexed text and queries normalize
--   identically.
-- * Demo listings: admins may seed sample data; `is_demo` marks it so the app
--   can label it and admins can purge it. Clients cannot set it.
-- * Realtime: the app refreshes feeds via `postgres_changes`, so the boards and
--   profile/admin tables must be part of the `supabase_realtime` publication.

-- ---------------------------------------------------------------------------
-- helpers: Arabic-aware normalization (mirrors Dart normalizeSearchText)
-- ---------------------------------------------------------------------------
create or replace function public.normalize_ar(input text)
returns text
language sql
immutable
as $fn$
  with s0 as (
    -- lowercase + strip tashkeel / tatweel / superscript alef / Quran marks
    select regexp_replace(
      lower(coalesce(input, '')),
      U&'[\064B-\0652\0640\0670\06D6-\06ED]',
      '',
      'g'
    ) as s
  ),
  s1 as (select replace(s, U&'\0623', U&'\0627') as s from s0),  -- أ -> ا
  s2 as (select replace(s, U&'\0625', U&'\0627') as s from s1),  -- إ -> ا
  s3 as (select replace(s, U&'\0622', U&'\0627') as s from s2),  -- آ -> ا
  s4 as (select replace(s, U&'\0671', U&'\0627') as s from s3),  -- ٱ -> ا
  s5 as (select replace(s, U&'\0649', U&'\064A') as s from s4),  -- ى -> ي
  s6 as (select replace(s, U&'\0624', U&'\0648') as s from s5),  -- ؤ -> و
  s7 as (select replace(s, U&'\0626', U&'\064A') as s from s6),  -- ئ -> ي
  s8 as (select replace(s, U&'\0629', U&'\0647') as s from s7)   -- ة -> ه
  select s from s8;
$fn$;

-- ---------------------------------------------------------------------------
-- rebuild generated search_text with the normalizer (drops + recreates indexes)
-- ---------------------------------------------------------------------------
alter table public.listings drop column search_text;
alter table public.listings add column search_text text generated always as (
  public.normalize_ar(
    coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
    coalesce(category, '') || ' ' || coalesce(wilaya, '') || ' ' ||
    coalesce(commune, ''))
) stored;
create index listings_search_trgm_idx
  on public.listings using gin (search_text gin_trgm_ops);

alter table public.requests drop column search_text;
alter table public.requests add column search_text text generated always as (
  public.normalize_ar(
    coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
    coalesce(category, '') || ' ' || coalesce(wilaya, '') || ' ' ||
    coalesce(commune, ''))
) stored;
create index requests_search_trgm_idx
  on public.requests using gin (search_text gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- demo listings: admins may seed; clients may not forge the flag
-- ---------------------------------------------------------------------------
alter table public.listings
  add column is_demo boolean not null default false;

-- On insert: only admins (or the service role, where auth.uid() is null) may
-- set is_demo = true. Everyone else is silently clamped to false.
create or replace function public.listings_demo_guard()
returns trigger
language plpgsql
as $$
begin
  if new.is_demo and auth.uid() is not null and not public.is_admin() then
    new.is_demo := false;
  end if;
  return new;
end $$;

create trigger listings_demo_guard_trg
  before insert on public.listings
  for each row execute function public.listings_demo_guard();

-- On update: freeze is_demo for non-admins (replaces 0002 listings_guard).
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

-- ---------------------------------------------------------------------------
-- Realtime: publish the tables the app streams, with full row images
-- ---------------------------------------------------------------------------
alter table public.listings      replica identity full;
alter table public.requests      replica identity full;
alter table public.reports       replica identity full;
alter table public.profiles      replica identity full;
alter table public.listing_images replica identity full;

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'listings', 'listing_images', 'requests', 'reports', 'profiles'
  ]
  loop
    if not exists (
      select 1 from pg_publication_tables
       where pubname = 'supabase_realtime'
         and schemaname = 'public'
         and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
