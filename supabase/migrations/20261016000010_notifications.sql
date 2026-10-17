-- Ta3awen — in-app notification inbox (Supabase-native, no push provider).
--
-- Notifications are created server-side by the same lifecycle transitions the
-- guard triggers already enforce, and delivered to the client over Realtime.
-- There is intentionally NO FCM/APNs dependency: the app shows a bell + unread
-- badge and a notifications list; a row is visible live while the app is open,
-- or on the next launch otherwise.
--
-- Design:
-- * `user_id` is the recipient; the row carries a `type`, the actor's display
--   name and the referenced listing/request. Text is NOT stored (the app is
--   ar/en/fr) — the client renders a localized message from `type`.
-- * Recipients may only SELECT their own rows and flip `read_at`; INSERT is
--   possible solely through SECURITY DEFINER triggers, so nobody can forge a
--   notification (not even for themselves).
-- * Rows cascade with their listing/request, and with the recipient's account.

-- ---------------------------------------------------------------------------
-- table
-- ---------------------------------------------------------------------------
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  type       text not null check (type in (
               'listing_claimed', 'listing_released', 'listing_given',
               'request_matched', 'blood_matched',
               'request_released', 'request_closed', 'report_new')),
  actor_name text not null default '' check (char_length(actor_name) <= 100),
  listing_id uuid references public.listings(id) on delete cascade,
  request_id uuid references public.requests(id) on delete cascade,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_created_idx
  on public.notifications (user_id, created_at desc);
create index notifications_user_unread_idx
  on public.notifications (user_id) where read_at is null;

-- ---------------------------------------------------------------------------
-- grants + RLS
--   read + mark-as-read only; no INSERT/UPDATE beyond `read_at`.
-- ---------------------------------------------------------------------------
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
grant delete on public.notifications to authenticated;
grant all on public.notifications to service_role;

alter table public.notifications enable row level security;

create policy notifications_select on public.notifications
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy notifications_update_read on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy notifications_delete on public.notifications
  for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

create policy notifications_admin_all on public.notifications
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- listings: notify on the transitions that matter to the other side
--   متاح -> محجوز   : tell the owner their item was reserved
--   محجوز -> متاح   : tell the owner a reservation was released
--   -> تم التبرع به : tell the claimant the owner confirmed delivery
-- Runs AFTER UPDATE so it sees the final, guard-normalized row.
-- The guard triggers prevent self-claims and self-matches, so the actor and
-- the recipient are always different people.
-- ---------------------------------------------------------------------------
create or replace function public.notify_listing_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
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

create trigger listings_notify_trg
  after update on public.listings
  for each row execute function public.notify_listing_change();

-- ---------------------------------------------------------------------------
-- requests: open -> matched (author), matched -> open (author, if matcher
-- released), matched -> closed (matcher). Blood posts get their own type.
-- ---------------------------------------------------------------------------
create or replace function public.notify_request_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
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

create trigger requests_notify_trg
  after update on public.requests
  for each row execute function public.notify_request_change();

-- ---------------------------------------------------------------------------
-- reports: tell every admin a new report landed in the moderation queue.
-- ---------------------------------------------------------------------------
create or replace function public.notify_new_report()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.notifications (user_id, type, actor_name, listing_id)
  select a.user_id, 'report_new', coalesce(new.reporter_name, ''), new.listing_id
    from public.admins a;
  return null;
end $$;

create trigger reports_notify_trg
  after insert on public.reports
  for each row execute function public.notify_new_report();

-- ---------------------------------------------------------------------------
-- Realtime: stream the recipient's rows (badge + live list).
-- ---------------------------------------------------------------------------
alter table public.notifications replica identity full;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
