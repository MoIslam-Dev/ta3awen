-- Ta3awen — Row Level Security. Mirrors firestore.rules.
-- All content requires an authenticated user unless noted.

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
revoke all on all tables in schema public from anon;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

create policy profiles_insert on public.profiles
  for insert to authenticated
  with check (id = auth.uid());

create policy profiles_update_self on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy profiles_admin_all on public.profiles
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- admins
-- ---------------------------------------------------------------------------
alter table public.admins enable row level security;

create policy admins_select on public.admins
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy admins_admin_all on public.admins
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- listings
-- ---------------------------------------------------------------------------
alter table public.listings enable row level security;

create policy listings_select on public.listings
  for select to authenticated
  using (true);

create policy listings_insert on public.listings
  for insert to authenticated
  with check (owner_id = auth.uid());

-- owner content edits / canonical status flips (guarded by trigger)
create policy listings_update_owner on public.listings
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- non-owner reserves an available listing
create policy listings_claim on public.listings
  for update to authenticated
  using (status = 'متاح' and owner_id <> auth.uid())
  with check (status = 'محجوز' and claimed_by = auth.uid());

-- claimant releases the reservation
create policy listings_release on public.listings
  for update to authenticated
  using (status = 'محجوز' and claimed_by = auth.uid())
  with check (status = 'متاح' and claimed_by is null);

create policy listings_delete on public.listings
  for delete to authenticated
  using (owner_id = auth.uid() or public.is_admin());

create policy listings_admin_all on public.listings
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- listing_images
-- ---------------------------------------------------------------------------
alter table public.listing_images enable row level security;

create policy listing_images_select on public.listing_images
  for select to authenticated
  using (true);

create policy listing_images_owner on public.listing_images
  for all to authenticated
  using (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.owner_id = auth.uid()))
  with check (exists (
    select 1 from public.listings l
    where l.id = listing_id and l.owner_id = auth.uid()));

create policy listing_images_admin_all on public.listing_images
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- requests
-- ---------------------------------------------------------------------------
alter table public.requests enable row level security;

create policy requests_select on public.requests
  for select to authenticated
  using (true);

create policy requests_insert on public.requests
  for insert to authenticated
  with check (uid = auth.uid());

create policy requests_update_author on public.requests
  for update to authenticated
  using (uid = auth.uid())
  with check (uid = auth.uid());

-- non-author matches an open post
create policy requests_match on public.requests
  for update to authenticated
  using (status = 'open' and uid <> auth.uid())
  with check (status = 'matched' and matched_by = auth.uid());

-- matcher releases (back to open)
create policy requests_release on public.requests
  for update to authenticated
  using (status = 'matched' and matched_by = auth.uid())
  with check (status = 'open' and matched_by is null);

create policy requests_delete on public.requests
  for delete to authenticated
  using (uid = auth.uid() or public.is_admin());

create policy requests_admin_all on public.requests
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- reports
-- ---------------------------------------------------------------------------
alter table public.reports enable row level security;

create policy reports_select_admin on public.reports
  for select to authenticated
  using (public.is_admin());

create policy reports_insert on public.reports
  for insert to authenticated
  with check (reporter_id = auth.uid());

create policy reports_admin_all on public.reports
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());
