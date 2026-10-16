# تعاون — Ta3awen

**الحاجة اللي ما تحتاجهاش، ممكن يحتاجها واحد آخر.**

Ta3awen (تعاون) is a free **Algerian social solidarity** Android application:
people offer things they no longer need (clothes, furniture, books, electronics,
food, accessibility equipment …) so another person can benefit from them. It is
**not a marketplace — there is no price field anywhere**. This is an ongoing
charitable project **in memory of the author's late mother — رحمها الله**.

The backend is **Supabase** (Postgres + Auth + Storage + Realtime). This README
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
The committed tests (89 tests) cover pure logic, models, widgets and the
pagination controller, but not the live Supabase-backed flows.

- **Accounts:** email/password registration, login, logout, password reset and a
  one-tap **Continue with Google** flow (first sign-in completes name + wilaya +
  commune).
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
                               └► Realtime     (postgres_changes)
```

- **Auth:** email/password + Google (native id-token exchange). Email
  confirmation is disabled (`mailer_autoconfirm`) so registration signs the user
  in immediately. A DB trigger (`handle_new_user`) seeds a profile row for
  email/password accounts as a safety net.
- **Database:** Postgres tables `profiles`, `admins`, `listings`, `listing_images`,
  `requests`, `reports`. Authorization is **Row Level Security + guard triggers**
  (the source of truth); the UI only reflects them.
- **Search:** each row has a generated, normalized `search_text` column with a
  trigram GIN index (`normalize_ar()` mirrors the client `normalizeSearchText`).
- **Images:** uploaded to the **Storage bucket `listings`** at
  `{listing_id}/{idx}.jpg` (plus a 480px `cover.jpg`); write access is owner-only
  (or admin).
- **Counters / lifecycle:** `profiles.post_count` is a server-owned anti-spam
  counter; listing/request status transitions are enforced by triggers.

### Migrations (`supabase/migrations/`)

| Version | Purpose |
|---|---|
| `0001_schema` | tables, constraints, indexes |
| `0002_functions` | helpers, lifecycle guards, admin RPCs |
| `0003_rls` | Row Level Security policies + grants |
| `0004_storage` | `listings` bucket + storage policies |
| `0005_fix_profiles_writes` | column-level profile writes (anti-spam safe) |
| `0006_search_and_realtime` | `normalize_ar`, normalized `search_text`, Realtime publication |
| `0007_auto_profile` | auto-create profile for email/password sign-ups |

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

## 8. Languages and theme

- `flutter_localizations` + ARB files under `lib/l10n/` (`app_ar.arb` is the
  template): **Arabic, French, English** (regenerate with `flutter gen-l10n`).
- Arabic is the default; the app is RTL-aware. Material 3, brand green `#2E7D32`,
  light/dark/system. Preferences stored with `shared_preferences`.

## 9. Pagination and states

Reads use a **live head page + one-shot older pages**, implemented once in
`PagedList<T>` and reused for the feeds, the boards, "إعلاناتي/محجوزاتي/طلباتي"
and the admin tabs. First-load uses shimmering skeletons, then `EmptyView` /
`ErrorView` with pull-to-refresh and retry. Feeds refresh live via Supabase
Realtime.

## 10. Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter 3.29.0 (Dart 3.7.0), Material 3, Android-first; RTL/LTR |
| Auth | Supabase Auth (email/password + Google) |
| Database | Supabase Postgres (RLS + triggers) |
| Images | Supabase Storage (`listings` bucket) |
| Security | Row Level Security + guard triggers (server-enforced) |
| Realtime | Supabase Realtime (`postgres_changes`) |
| Geography | Local static dataset: 58 wilayas + 1527 communes |

Dart dependencies include `supabase_flutter`, `google_sign_in`, `image_picker`,
`image`, `intl`, `shared_preferences`.

```
lib/
  main.dart              # Supabase init, locale/theme, AuthGate
  core/supabase.dart     # client init + config
  models/                # AppUser, Listing, RequestPost, Report
  services/              # auth, user, listing, request, image, report, admin
  screens/               # auth, home, listing, requests, my_listings, profile,
                         # onboarding, admin
  widgets/               # cards, base64 image, skeletons, publish sheet, ...
  state/                 # paged_list, app_settings
  data/algeria_data.dart # 58 wilayas -> communes (static)
  l10n/                  # app_ar.arb (template), app_en.arb, app_fr.arb + gen/
test/                    # 89 tests
supabase/migrations/     # 0001..0007 SQL
```

## 11. Install, run, test, build

**Requirements:** Flutter 3.29.0 (Dart 3.7.0), JDK 17, Android SDK 35
(`minSdk 23`).

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

## 12. First admin

The first admin is seeded directly in the database (`public.admins`). After that,
existing admins can grant/revoke membership from the in-app panel. The seeded
account for this deployment uses the maintainer's email at wilaya `قسنطينة`,
commune `الخروب`.

## 13. Limitations

- No closed-app push notifications (a scheduled local-notification poll is not yet
  implemented).
- Board/admin search is client-side over the loaded pages; listing search is
  server-side.
- Phone numbers on listings/requests are readable by any signed-in user (the app
  relies on phone contact — no chat).
- iOS is not configured; the project is Android-first.

## 14. Distribution

- Source: https://github.com/MoIslam-Dev/ta3awen (branch `main`).
- Release APKs: https://github.com/MoIslam-Dev/ta3awen-apk.

---

Do not commit `android/key.properties`, `android/key/`, or any service-account /
secret keys.
