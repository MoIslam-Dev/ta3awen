-- Fix: profiles_guard froze post_count even for the trusted server-side
-- increment, so the anti-spam counter never advanced.
--
-- Replaced the trigger with COLUMN-LEVEL privileges: an authenticated user may
-- only UPDATE the four editable profile columns. post_count / disabled /
-- disabled_reason / email / created_at can only be changed by SECURITY DEFINER
-- functions (the counter trigger and the admin RPCs), which run as the owner.

drop trigger if exists profiles_guard_trg on public.profiles;
drop function if exists public.profiles_guard();

revoke update on public.profiles from authenticated;
grant update (full_name, wilaya, commune, contact_phone) on public.profiles to authenticated;
