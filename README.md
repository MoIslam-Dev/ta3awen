# تعاون — Ta3awen

**الحاجة اللي ما تحتاجهاش، ممكن يحتاجها واحد آخر.**

Ta3awen (تعاون) is a free **Algerian social solidarity** Android application:
people offer things they no longer need (clothes, furniture, books, electronics,
food, accessibility equipment …) so another person can benefit from them. It is
**not a marketplace — there is no price field anywhere**. This is an ongoing
charitable project **in memory of the author's late mother — رحمها الله**.

The backend is **Supabase** (Postgres + Auth + Storage + Realtime + Edge
Functions; FCM is used only as the OS push transport). This README
describes the project as it exists in this repository; every claim is grounded in
the Flutter source, the SQL migrations under `supabase/migrations/`, or the
automated tests.

---

## 1. Overview and mission

- Free, no-money exchange of goods between neighbours, organised by wilaya and
  commune (the Algerian administrative units).
- Contact happens **by phone**, not by in-app chat — so a contact phone number is
  required on every listing and board post.
- A single Flutter app talks directly to Supabase; all backend-specific code is
  isolated in `lib/services/`.
- The app runs on the **Supabase free tier** — no paid services.

## 2. Feature status

Every feature below is **implemented in the Flutter source and wired into the UI**.
The committed tests (98 tests) cover pure logic, models, widgets and the
pagination controller, but not the live Supabase-backed flows.

- **Accounts:** email/password registration, login, logout, password reset and a
  one-tap **Continue with Google** flow. After any sign-in the app gates on a
  **complete profile**: a session whose profile is missing wilaya + commune is
  routed to the completion screen, never straight into the app.
- **Feed:** available listings with thumbnail, title, category, condition,
  wilaya+commune and date; live updates on the newest page; pull-to-refresh; and
  cursor pagination.
- **Search & filters:** server-side full-text search (normalized trigram) plus
  category, wilaya and commune filters.
- **Listings lifecycle:** create, edit, delete; `متاح` → `محجوز` → `تم التبرع به`.
- **Reservations:** any signed-in non-owner can reserve ("claim"); owner confirms
  delivery; owner or claimant can release.
- **Community board ("أطلب"):** `need`/`offer` posts with category + wilaya +
  commune filters, plus a dedicated **blood-donation** board.
- **Reporting:** any signed-in user can report a listing (fixed reason list).
- **Notifications:** a server-fed inbox (bell + unread badge) **plus OS push**.
  Claim, match, delivery and report events create rows server-side; they stream
  live over Realtime, persist until read, and are also delivered to the device
  through FCM when the app is backgrounded or closed. See §8.
- **Publishing:** one FAB opens a single **publish sheet** with four intents
  (تبرع / تبادل / أطلب / دم).
- **Admin panel:** dashboard, report workflow, paginated listing/request/user/report
  lists, disable/enable users, grant/revoke admin, delete-user-data.
- **Profile:** view/edit name, wilaya, commune and optional phone; language + theme.
- **Languages:** Arabic (default), French, English; full RTL/LTR.
- **Themes:** light, dark, follow-system.

## 3. Backend architecture (Supabase)

```
Flutter app ──supabase_flutter──► PostgREST   (tables, RLS, RPC)
                               ├► GoTrue/Auth  (email+Google)
                               ├► Storage      (bucket `listings`)
                               ├► Realtime     (postgres_changes)
                               └► Edge Function `send-push` ──FCM──► device

notifications row ──trigger──► pg_net (net.http_post) ──► send-push
```

- **Auth:** email/password + Google (native id-token exchange). Email
  confirmation is disabled (`mailer_autoconfirm`) so registration signs the user
  in immediately. A DB trigger (`handle_new_user`) seeds a profile row for
  **every** new auth user (name from metadata/email, empty location); the app's
  `AuthGate` → `_ProfileGate` then decides between the completion screen and the
  home shell based on whether wilaya + commune are set.
- **Database:** Postgres tables `profiles`, `admins`, `listings`, `listing_images`,
  `requests`, `reports`, `notifications`, `device_tokens`. Authorization is
  **Row Level Security + guard triggers** (the source of truth); the UI only
  reflects them.
- **Push:** an **Edge Function `send-push`** (Deno) is invoked asynchronously by
  `pg_net` from a trigger on `notifications`, reads the recipient's
  `device_tokens`, localizes the message (ar/fr/en) and sends it via **FCM HTTP
  v1**. FCM is used **only as the OS transport** — Supabase remains the backend
  and the source of truth; no app data lives in Firebase. The webhook URL and a
  shared secret are read from **Vault**; the FCM service account and the webhook
  secret are Edge Function secrets (never in the repo).
- **Search:** each row has a generated, normalized `search_text` column with a
  trigram GIN index (`normalize_ar()` mirrors the client `normalizeSearchText`).
- **Images:** uploaded to the **Storage bucket `listings`** at
  `{listing_id}/{idx}.jpg` (plus a 480px `cover.jpg`); write access is owner-only
  (or admin).
- **Counters / lifecycle:** `profiles.post_count` is a server-owned anti-spam
  counter; listing/request status transitions are enforced by triggers.
- **Demo data:** admins may seed sample listings; the `is_demo` flag labels them
  and lets admins purge them. Clients cannot forge it.

### Migrations (`supabase/migrations/`)

| Version | Purpose |
|---|---|
| `0001_schema` | tables, constraints, indexes |
| `0002_functions` | helpers, lifecycle guards, admin RPCs |
| `0003_rls` | Row Level Security policies + grants |
| `0004_storage` | `listings` bucket + storage policies |
| `0005_fix_profiles_writes` | column-level profile writes (anti-spam safe) |
| `0006_search_and_realtime` | `normalize_ar`, normalized `search_text`, `is_demo` flag, Realtime publication |
| `0007_auto_profile` | `handle_new_user` trigger seeding a profile row |
| `0008_profile_seed_and_grants` | seed a profile for every new auth user (not just email) + restore `service_role` grants |
| `0009_fix_admin_claim` | normalize the claim shape before the admin fast-path, fixing admin reservations |
| `0010_notifications` | notification inbox: table, RLS, lifecycle triggers, Realtime |
| `0011_fix_admin_match` | normalize the match shape before the admin fast-path, fixing admin request matches |
| `0012_device_tokens` | FCM push transport: `device_tokens` + RLS, `register`/`unregister_device_token` RPCs, `pg_net` + `notifications_send_push` trigger calling the `send-push` Edge Function |

## 4. Listings and requests

**Listings** (`ListingService`, `ListingFormScreen`, `ListingDetailsScreen`):
title (≤80), description (≤800), category, condition, wilaya, commune, up to 5
images, **mandatory** contact phone. Create inserts the row, uploads images to
Storage and records their paths; on image failure the listing is deleted (no
half-created records).

**Requests / board** (`RequestService`, `RequestFormScreen`,
`RequestDetailsScreen`): community-board posts, either a **need** (`type=need`) or
an **offer** (`type=offer`), with title, description, category, wilaya, commune
and a phone; **no images**. The **blood board** (`kind=blood`) posts are always
`need`, use a fixed category and carry one of the 8 blood types. Status:
`open → matched → open/closed`.

## 5. Wilaya + commune filtering

- Geography is a **local static dataset** (`lib/data/algeria_data.dart`): 58
  wilayas and their 1527 communes.
- The feed exposes FilterChips for category, wilaya and commune; the **"أطلب"
  board** exposes the same category + wilaya + commune filters.
- Registration, profile editing and the post forms reuse the `WilayaCommuneFields`
  dropdown pair. Stored values are Arabic and never change with the UI language.

## 6. Image handling

`ImageService` picks up to 5 images (`maxWidth 1000`, quality 70) and builds a
480px JPEG thumbnail; `ListingService` uploads them to Storage and records
`listing_images` rows. The bucket caps writes to the owner (or admin) via RLS.

## 7. Reporting, moderation and admin

- Any signed-in user can report a listing (5 fixed reasons + optional note).
- Admin panel (gated by `AdminService.isAdmin`): dashboard counts, report
  workflow (resolve/dismiss/delete), paginated listing/request/user/report lists,
  disable/enable users with a reason, grant/revoke admin, and delete-user-data.
- Admin membership lives in `public.admins`; admins can manage it from the app via
  the `set_admin` RPC.

## 8. Notifications

An **in-app inbox** plus **OS push**, both server-fed from the same
`notifications` row:

- The DB creates notification rows through `SECURITY DEFINER` triggers on the
  listing/request lifecycle and on new reports, so a client can never forge one.
- Recipients may only read their own rows and flip `read_at`; inserts are
  trigger-only. Rows cascade with their listing/post and with the account.
- The app shows a **bell + unread badge** in the shell and a notifications
  screen (`NotificationCenter` + `NotificationService`), updated live via
  Realtime. Tapping a row marks it read and opens the referenced listing/post.
- Text is not stored: the row carries a `type` + actor name, so the app renders
  a localized message (ar/en/fr). See `20261016000010_notifications.sql`.

**Push delivery (`20261016000012_device_tokens.sql`).** An `AFTER INSERT` trigger
on `notifications` POSTs the row to the `send-push` Edge Function through
`pg_net`; the function looks up the recipient's `device_tokens`, builds the
localized title/body and calls **FCM HTTP v1**, pruning tokens FCM reports as
unregistered. On the device, `PushService` (`lib/services/push_service.dart`):

- initializes Firebase **after** `Firebase.initializeApp()` (lazy accessor),
- creates a high-importance channel (`ta3awen_default`, importance 4),
- registers the FCM token via the `register_device_token` RPC after sign-in and
  refreshes it on `onTokenRefresh`, storing the device locale for localization;
- shows a foreground heads-up and, for background/terminated taps, deep-links
  through `appNavigatorKey` straight to the referenced listing/post.

Push uses FCM as the transport only; the inbox and all data stay in Supabase.
`device_tokens` is protected by RLS (each user sees/deletes only their own) and
tokens are written exclusively through the RPCs.

## 9. Languages and theme

- `flutter_localizations` + ARB files under `lib/l10n/` (`app_ar.arb` is the
  template): **Arabic, French, English** (regenerate with `flutter gen-l10n`).
- Arabic is the default; the app is RTL-aware. Material 3, brand green `#2E7D32`,
  light/dark/system. Preferences stored with `shared_preferences`.

## 10. Pagination and states

Reads use a **live head page + one-shot older pages**, implemented once in
`PagedList<T>` and reused for the feeds, the boards, "إعلاناتي/محجوزاتي/طلباتي"
and the admin tabs. First-load uses shimmering skeletons, then `EmptyView` /
`ErrorView` with pull-to-refresh and retry. Feeds and the notification inbox
refresh live via Supabase Realtime.

## 11. Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter 3.29.0 (Dart 3.7.0), Material 3, Android-first; RTL/LTR |
| Auth | Supabase Auth (email/password + Google) |
| Database | Supabase Postgres (RLS + triggers) |
| Images | Supabase Storage (`listings` bucket) |
| Security | Row Level Security + guard triggers (server-enforced) |
| Realtime | Supabase Realtime (`postgres_changes`) |
| Notifications | Server-fed inbox (DB triggers + Realtime) + OS push via FCM HTTP v1 (Edge Function `send-push`, `pg_net`) |
| Geography | Local static dataset: 58 wilayas + 1527 communes |

Dart dependencies include `supabase_flutter`, `google_sign_in`, `image_picker`,
`image`, `intl`, `shared_preferences`, `firebase_core`, `firebase_messaging` and
`flutter_local_notifications`.

```
lib/
  main.dart              # Supabase init, locale/theme, AuthGate
  core/supabase.dart     # client init + config
  models/                # AppUser, Listing, RequestPost, Report, AppNotification
  services/              # auth, user, listing, request, image, report, admin,
                         # notification, push (FCM)
  core/navigator.dart    # appNavigatorKey (out-of-tree deep-links)
  screens/               # auth, home, listing, requests, my_listings, profile,
                         # onboarding, notifications, admin
  widgets/               # cards, base64 image, skeletons, publish sheet, ...
  state/                 # paged_list, app_settings, notification_center
  data/algeria_data.dart # 58 wilayas -> communes (static)
  l10n/                  # app_ar.arb (template), app_en.arb, app_fr.arb + gen/
test/                    # 98 tests
supabase/migrations/     # 0001..0012 SQL
supabase/functions/      # send-push Edge Function (FCM HTTP v1)
```

## 12. Install, run, test, build

**Requirements:** Flutter 3.29.0 (Dart 3.7.0), JDK 17, Android SDK 35
(`minSdk 24` — required by the FCM plugins), Kotlin Gradle plugin 2.1.0 and
core-library desugaring (both configured in `android/`). FCM needs the
`android/app/google-services.json` (Firebase project) and Edge Function secrets
(see §8); the OS push itself does not depend on an app-signing SHA-1.

```bash
flutter pub get
flutter gen-l10n                 # regenerate localized strings

flutter analyze                  # static analysis
flutter test                     # unit + widget tests

flutter build apk --release      # universal APK
flutter build apk --release --split-per-abi   # per-CPU APKs (recommended)
```

Output: `build/app/outputs/flutter-apk/`.

**Release signing:** `android/key/ta3awen-upload.jks` plus
`android/key.properties` (the password lives in `key.properties`). Both are
gitignored and must never be committed — back them up safely.

## 13. First admin

The first admin is seeded directly in the database (`public.admins`). After that,
existing admins can grant/revoke membership from the in-app panel. The seeded
account for this deployment uses the maintainer's email at wilaya `قسنطينة`,
commune `الخروب`.

## 14. Limitations

- **Push is Android-only.** OS push is delivered through FCM on Android; there
  is no APNs/iOS configuration (the project is Android-first). Push depends on
  the `send-push` Edge Function and its secrets, which are not part of the repo,
  so a fresh clone cannot deliver OS push until those are provisioned.
- Board/admin search is client-side over the loaded pages; listing search is
  server-side.
- Phone numbers on listings/requests are readable by any signed-in user (the app
  relies on phone contact — no chat).
- iOS is not configured; the project is Android-first.

## 15. Distribution

- Source: https://github.com/MoIslam-Dev/ta3awen (branch `main`).
- Release APKs: https://github.com/MoIslam-Dev/ta3awen-apk.

---

Do not commit `android/key.properties`, `android/key/`, or any service-account /
secret keys.
