-- Ta3awen — core schema (Supabase / Postgres).
--
-- Design notes:
-- * Stored VALUES are identical to the current Flutter constants: listing
--   status/kind stay Arabic ('متاح' / 'محجوز' / 'تم التبرع به', 'تبرع' / 'تبادل'),
--   request/report values stay English. So the Dart models keep working.
-- * The old Firestore `keywords` prefix-array is gone; search is a generated
--   `search_text` column with a trigram GIN index (partial + multi-word AND).
-- * The old `stats/{uid}` counter is folded into `profiles.post_count`, which is
--   incremented server-side by a trigger (closes the batched-create caveat).
-- * Identity columns reference auth.users so deleting an auth user cascades.

create extension if not exists pg_trgm;

-- ---------------------------------------------------------------------------
-- profiles  (was: users/{uid})
-- ---------------------------------------------------------------------------
create table public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text not null check (char_length(full_name) between 1 and 100),
  email           text not null default '' check (char_length(email) <= 200),
  wilaya          text not null default '' check (char_length(wilaya) <= 60),
  commune         text not null default '' check (char_length(commune) <= 60),
  contact_phone   text check (contact_phone is null or char_length(contact_phone) <= 20),
  disabled        boolean not null default false,
  disabled_reason text,
  post_count      integer not null default 0 check (post_count >= 0),
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- admins  (was: admins/{uid})
-- ---------------------------------------------------------------------------
create table public.admins (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- listings  (was: listings/{id}); images move to Storage, not base64
-- ---------------------------------------------------------------------------
create table public.listings (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users(id) on delete cascade,
  owner_name      text not null default '' check (char_length(owner_name) <= 100),
  title           text not null check (char_length(title) between 1 and 80),
  description     text not null default '' check (char_length(description) <= 800),
  category        text not null check (char_length(category) between 1 and 50),
  wilaya          text not null check (char_length(wilaya) between 1 and 60),
  commune         text not null check (char_length(commune) between 1 and 60),
  condition       text not null check (char_length(condition) between 1 and 20),
  status          text not null default 'متاح'
                    check (status in ('متاح', 'محجوز', 'تم التبرع به')),
  kind            text not null default 'تبرع' check (kind in ('تبرع', 'تبادل')),
  contact_phone   text check (contact_phone is null or char_length(contact_phone) between 9 and 20),
  image_count     integer not null default 0 check (image_count between 0 and 5),
  cover_path      text,                      -- Storage object path for the 480px cover
  claimed_by      uuid references auth.users(id) on delete set null,
  claimed_by_name text check (claimed_by_name is null or char_length(claimed_by_name) <= 100),
  claimed_at      timestamptz,
  search_text     text generated always as (
    lower(coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
          coalesce(category, '') || ' ' || coalesce(wilaya, '') || ' ' ||
          coalesce(commune, ''))
  ) stored,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  -- A claim is all-or-nothing.
  constraint listings_claim_shape check (
    (claimed_by is null and claimed_at is null) or
    (claimed_by is not null and claimed_at is not null)
  )
);

create index listings_status_created_idx  on public.listings (status, created_at desc);
create index listings_owner_created_idx   on public.listings (owner_id, created_at desc);
create index listings_claimed_created_idx on public.listings (claimed_by, created_at desc);
create index listings_wilaya_commune_idx  on public.listings (wilaya, commune);
create index listings_kind_idx            on public.listings (kind);
create index listings_search_trgm_idx     on public.listings using gin (search_text gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- listing_images  (Storage objects, keyed by index; caps a listing at 5)
-- ---------------------------------------------------------------------------
create table public.listing_images (
  listing_id   uuid not null references public.listings(id) on delete cascade,
  idx          integer not null check (idx between 0 and 4),
  storage_path text not null,
  primary key (listing_id, idx)
);

-- ---------------------------------------------------------------------------
-- requests  (was: requests/{id}) — the community / blood board
-- ---------------------------------------------------------------------------
create table public.requests (
  id            uuid primary key default gen_random_uuid(),
  uid           uuid not null references auth.users(id) on delete cascade,
  user_name     text not null default '' check (char_length(user_name) <= 100),
  type          text not null check (type in ('need', 'offer')),
  title         text not null check (char_length(title) between 1 and 80),
  description   text not null default '' check (char_length(description) <= 800),
  category      text not null check (char_length(category) between 1 and 50),
  wilaya        text not null check (char_length(wilaya) between 1 and 60),
  commune       text not null check (char_length(commune) between 1 and 60),
  contact_phone text check (contact_phone is null or char_length(contact_phone) between 9 and 20),
  status        text not null default 'open' check (status in ('open', 'matched', 'closed')),
  kind          text not null default 'general' check (kind in ('general', 'blood')),
  blood_type    text check (blood_type in ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  matched_by    uuid references auth.users(id) on delete set null,
  matched_name  text check (matched_name is null or char_length(matched_name) <= 100),
  matched_at    timestamptz,
  search_text   text generated always as (
    lower(coalesce(title, '') || ' ' || coalesce(description, '') || ' ' ||
          coalesce(category, '') || ' ' || coalesce(wilaya, '') || ' ' ||
          coalesce(commune, ''))
  ) stored,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint requests_blood_shape check (
    kind <> 'blood' or (type = 'need' and blood_type is not null)
  ),
  constraint requests_match_shape check (
    (matched_by is null and matched_at is null) or
    (matched_by is not null and matched_at is not null)
  )
);

create index requests_status_created_idx       on public.requests (status, created_at desc);
create index requests_status_kind_created_idx  on public.requests (status, kind, created_at desc);
create index requests_status_kind_type_created_idx
  on public.requests (status, kind, type, created_at desc);
create index requests_uid_created_idx          on public.requests (uid, created_at desc);
create index requests_search_trgm_idx          on public.requests using gin (search_text gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- reports  (was: reports/{id})
-- `status` now defaults to 'open' in the DB, so legacy "missing status" is gone
-- and admin filtering can be fully server-side.
-- ---------------------------------------------------------------------------
create table public.reports (
  id            uuid primary key default gen_random_uuid(),
  listing_id    uuid references public.listings(id) on delete set null,
  listing_title text not null default '' check (char_length(listing_title) <= 80),
  reporter_id   uuid not null references auth.users(id) on delete cascade,
  reporter_name text not null default '' check (char_length(reporter_name) <= 100),
  reason        text not null check (reason in (
                  'محتوى غير مناسب', 'معلومات كاذبة',
                  'الغرض تم الحصول عليه مسبقاً', 'إعلان مكرر', 'أخرى')),
  description   text check (description is null or char_length(description) <= 1000),
  status        text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  resolved_at   timestamptz,
  created_at    timestamptz not null default now()
);

create index reports_status_created_idx on public.reports (status, created_at desc);
create index reports_reporter_idx       on public.reports (reporter_id);
