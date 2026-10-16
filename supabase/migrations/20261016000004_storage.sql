-- Ta3awen — Storage bucket for listing images.
-- Replaces the base64-in-Firestore approach: files live at
--   listings/{listing_id}/{idx}.jpg
-- and only the listing owner (or an admin) may write them.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listings', 'listings', true, 1048576, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "listing images are publicly readable"
  on storage.objects for select
  using (bucket_id = 'listings');

create policy "owners can upload listing images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listings'
    and exists (
      select 1 from public.listings l
      where l.id::text = (storage.foldername(name))[1]
        and l.owner_id = auth.uid()
    )
  );

create policy "owners can update listing images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'listings'
    and exists (
      select 1 from public.listings l
      where l.id::text = (storage.foldername(name))[1]
        and l.owner_id = auth.uid()
    )
  );

create policy "owners or admins can delete listing images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'listings'
    and (
      exists (
        select 1 from public.listings l
        where l.id::text = (storage.foldername(name))[1]
          and l.owner_id = auth.uid()
      )
      or public.is_admin()
    )
  );
