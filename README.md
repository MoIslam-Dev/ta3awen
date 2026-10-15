# تعاون — Ta3awen

**الحاجة اللي ما تحتاجهاش، ممكن يحتاجها واحد آخر.**

Ta3awen (تعاون) is a free **Algerian social solidarity** Android application:
people offer things they no longer need (clothes, furniture, books, electronics,
food, accessibility equipment …) so another person can benefit from them. It is
**not a marketplace — there is no price field anywhere**. This is an ongoing
charitable project **in memory of the author's late mother — رحمها الله**.

This README describes the project as it exists in this repository. Every claim is
grounded in the Flutter source, the Firestore security rules, or the automated
tests; whenever something is only implemented but not covered by an automated
test, or still depends on a live Firebase project and a physical device, that is
stated explicitly. **The app is a working prototype/MVP, not a production-ready
product** — see §16 for the status and §14 for the known limitations.

---

## 1. Overview and mission

- Free, no-money exchange of goods between neighbours, organised by wilaya and
  commune (the Algerian administrative units).
- Contact happens **by phone**, not by in-app chat — so a contact phone number is
  required on every listing and board post.
- The project is intentionally lean: a single Flutter app talking directly to
  Firebase, with all Firebase-specific code isolated in `lib/services/` so the
  data layer could later be swapped (e.g. for a REST backend) without touching
  the screens or models.
- It runs on the **free Firebase tier only** (no billing account, no Cloud
  Functions, no paid services). This constraint shapes several decisions
  documented below (base64 images, no closed-app push notifications).

## 2. Feature status — implemented vs. tested

Every feature below is **implemented in the Flutter source and wired into the UI**.
The committed tests (13 files, 89 tests) cover pure logic, models, widgets and the
pagination controller, but **not** the Firebase-backed flows (authentication,
create/edit/reserve, admin actions). "Implemented" therefore means the code path
exists; it is not a claim that every flow has been verified end-to-end. See §16 for
the test breakdown and the overall status.

- **Accounts:** email/password registration, login, logout, password reset, and a
  one-tap **Continue with Google** flow (first sign-in completes name + wilaya +
  commune so every profile has a location).
- **Feed:** available listings with thumbnail, title, category, condition,
  wilaya+commune and date; live updates on the newest page; pull-to-refresh; and
  cursor pagination behind the "المزيد" button.
- **Search & filters:** full-text search (server-side keyword index, see §9) plus
  category, wilaya and commune filters, applied as Firestore equality clauses.
- **Listings lifecycle:** create, edit, delete, and a three-state status
  `متاح` (available) → `محجوز` (reserved) → `تم التبرع به` (donated).
- **Reservations:** any signed-in non-owner can reserve ("claim") a listing;
  owner confirms delivery; owner or claimant can release; races are handled.
- **Community requests board:** `need`/`offer` posts, plus a dedicated
  **blood-donation** board (`kind=blood`, fixed to `need`, with a blood type).
  Posts can be matched, the match withdrawn/released, finalised (closed) and
  reopened.
- **Reporting:** any signed-in user can report a listing (fixed reason list +
  optional note).
- **Publishing:** a single FAB opens one **publish sheet** with the four intents
  (تبرع / تبادل / أطلب / دم), so there is exactly one place to create anything.
- **Admin panel:** dashboard built from cheap count aggregations, report workflow
  (resolve / dismiss / delete-content), **paginated** listing / request / user /
  report lists, user detail with disable/enable (with reason), grant/revoke admin,
  delete-all-user-data, and a one-click **seed-data cleanup**.
- **Profile:** view and edit name, wilaya, commune and optional contact phone;
  language and theme pickers.
- **UI polish:** shimmering skeleton loaders on first load, branded image
  placeholders, a multi-photo badge, a gallery counter + scrim, and Material 3
  page transitions.
- **Onboarding:** a first-launch "how it works" screen, re-openable from Profile.
- **Languages:** Arabic (default), French and English, full RTL/LTR.
- **Themes:** light, dark and follow-system.

## 3. Authentication and account management

- Firebase Authentication, **email + password**, plus a one-tap
  **Continue with Google** (`google_sign_in`).
- `AuthGate` (`lib/screens/auth_gate.dart`) listens to `authStateChanges()` and
  shows a branded splash while resolving, then either `LoginScreen` or
  `HomeShell`. Every auth flow returns to a **fresh** `AuthGate` so the stream is
  never left unobserved.
- Login fails fast: `signInWithEmailAndPassword` is wrapped in a 20-second
  timeout so a flaky connection surfaces a clear error instead of a spinner
  (`lib/services/auth_service.dart`).
- **Google sign-in** (`AuthService.signInWithGoogle`, `lib/utils/google_auth.dart`)
  turns the Google account into a Firebase identity. If a `users/{uid}` profile
  already exists the user lands on the home shell; on a first sign-in the short
  `SocialSetupScreen` collects name + wilaya + commune and creates the profile.
  Platform cancellations (sheet closed) are treated as "not an error", while a
  misconfigured client (bad/absent SHA-1 → `INVALID_CLIENT_APPLICATION`) maps to a
  configuration hint via `authErrorMessage`.
- On registration a `users/{uid}` profile document is created
  (`fullName`, `email`, `wilaya`, `commune`) — `lib/screens/auth/register_screen.dart`
  + `UserService.createAppUser`.
- Password reset is done by email (`AuthService.sendPasswordReset`).
- Auth errors are mapped to localized, human messages (`lib/utils/errors.dart`,
  covered by `test/auth_error_mapping_test.dart`).
- Profiles can be edited from the Profile tab (`EditProfileScreen`): name,
  wilaya, commune and an optional phone validated against Algerian mobile
  numbers (`^0[2-7]\d{8}$`, with `+213` / `00213` normalisation).
- **Disabled accounts:** an admin can disable a user with a reason; the rules
  then block that user from writing listings or requests (`canWrite()`).

## 4. Listings and requests — create, edit, delete, complete

**Listings** (`ListingService`, `ListingFormScreen`, `ListingDetailsScreen`):

- Fields: title (≤80), description (≤800), category (10 fixed values), condition
  (4 values), wilaya, commune, up to 5 images, **mandatory** contact phone. No
  price field exists.
- Create writes the listing document and bumps the anti-spam counter in one
  batch, then writes the image sub-documents (`create` commits the listing
  first, and deletes the listing if the images fail — no half-created records).
- Edit rewrites the searchable `keywords` and can replace images.
- Status lifecycle is enforced by both the UI and the rules:
  `متاح → محجوز → تم التبرع به`. The owner may also toggle `متاح ↔ تم التبرع به`
  directly (the historical behaviour); a reservation only leaves `محجوز`
  through the dedicated claim/cancel/confirm paths.
- **Claim** (reserve): a non-owner reserves an available listing. On a rules
  denial the screen re-reads the document to distinguish "someone else won the
  race" from a generic error.
- **Confirm delivery:** owner-only; keeps the claim fields so the community can
  see who received the item.
- **Cancel/release:** owner or claimant returns it to `متاح`.

**Requests / board** (`RequestService`, `RequestFormScreen`,
`RequestDetailsScreen`). The Firestore collection is named `requests`, but each
document is a **community-board post** — a short "assistance request" that is
either a **need** (`type=need`, "I need …") or an **offer** (`type=offer`,
"I can give …"). This board is intentionally **separate from the `listings`
collection**:

- `listings` = items offered for donation, with images and a reserve/confirm
  flow.
- `requests` = lightweight board posts for needs and offers, **no images**, with a
  match workflow.

Matching connects the two sides of the board (a need answered by another user); it
does **not** turn a board post into a listing.

- A post is `type=need` or `type=offer`, with title, description, category,
  wilaya, commune and a contact phone. The board holds **no images**.
- **Blood board:** `kind=blood` posts are always `need`, use a fixed category
  (`التبرع بالدم`) and carry one of the 8 blood types (`A+ … O-`). Edits may never
  convert a post between `general` and `blood`.
- Status lifecycle: `open → matched` (another user answers) → `open` (withdraw /
  release) or `closed` (author finalises); author may toggle `open ↔ closed`.
- New posts always start `open`; the create shape deliberately omits the match
  keys (the rules reject them).

## 5. Wilaya + commune filtering

- Geography is a **local static dataset** — no maps, no external API:
  `lib/data/algeria_data.dart` holds all **58 wilayas** and their **1527
  communes** (verified by a unit test asserting 58 wilayas).
- The feed exposes FilterChips for category, wilaya and (once a wilaya is
  chosen) commune; changing any of them re-runs a server-side query with the
  corresponding `where(... isEqualTo ...)` clauses.
- Registration, profile editing and both post forms reuse the same
  `WilayaCommuneFields` dropdown pair (commune list depends on the wilaya).
- Stored values are Arabic and never change with the UI language; the UI maps
  them to localized labels (`lib/utils/labels.dart`).

## 6. Image handling and storage

- Images are compressed in-app and stored as **base64 strings inside Firestore**
  (`ImageService`):
  - `pickMultiImage` limited to **5 images**, `maxWidth 1000`, quality 70.
  - The first image is downscaled to a **480 px** JPEG (quality 55) and kept as
    the `image0` thumbnail on the listing document for fast feed rendering.
  - Full images live in the `listings/{id}/images/{0..4}` subcollection, keyed by
    index (which itself caps a listing at 5 images).
- `B64Cache` (`lib/utils/b64_cache.dart`) decodes each base64 payload at most
  once (small LRU-ish cache, cleared past 80 entries).
- Rules bound the storage: `imageCount 0…5`, each image `data` string
  `< 900000` bytes, `image0 < 150000` characters, and only the listing owner (or
  an admin) may write or delete image documents.

**Why base64 instead of Firebase Storage?** New Cloud Storage buckets require the
pay-as-you-go Blaze plan (card on file), and this project deliberately stays on
the free tier. Storing base64 in Firestore keeps everything free and needs no
billing account. To migrate later, only `lib/services/image_service.dart` and the
`ListingService` create/update/images methods need to change — screens and models
do not (service isolation).

## 7. Reporting, moderation and admin

- **Reporting** (`ReportService`, `ListingDetailsScreen`): any signed-in user can
  report a listing using one of 5 fixed reasons plus an optional note (≤1000
  chars). `Report.toMap()` deliberately writes only the rule allow-list, so
  creation never trips the rules' `hasOnly()` check.
- **Report workflow:** reports start `open` and an admin marks them `resolved`
  or `dismissed` (with a `resolvedAt` timestamp). "Resolve + delete content"
  removes the reported listing and its images in a single batch.
- **Admin panel** (`AdminScreen`, gated by `AdminService.isAdmin`), five lazy
  tabs (`DefaultTabController`; each tab loads its own data only when shown):
  1. **Dashboard** — statistics built entirely from Firestore **`count()`
     aggregations** (≈1 read per 1000 documents), so no documents are loaded:
     users, disabled users, listings (total/available/reserved/donated), open
     reports, requests (total/open/matched) and blood requests — plus the
     seed-data cleanup action.
  2. **Reports** — paginated list; open/resolved/dismissed filter (client-side,
     because legacy reports have no `status`), open the reported listing, resolve,
     dismiss, delete content, delete report.
  3. **Listings** — paginated; status filter server-side, text search client-side
     over the loaded pages; open or delete.
  4. **Users** — paginated; name search server-side (prefix range on `fullName`);
     detail sheet (phone, location, join date, listing/request counts via
     aggregations), disable/enable with a reason, **grant/revoke admin**, and
     **delete all user data** (listings + images, requests, filed reports, `stats`
     and profile).
  5. **Requests** — paginated; status filter server-side, kind filter client-side;
     open or delete.
- **Every admin list is paginated** (`kPageSize = 20`): a live first page plus
  one-shot older pages via `startAfterDocument`. The console never opens several
  full-collection listeners at once.
- **Admins can manage admin membership from the app**: `AdminService.setAdmin`
  writes/deletes `admins/{uid}` and the rules allow it for existing admins (§12).
- **Seed cleanup:** demo listings use document IDs prefixed `seed-`; the dashboard
  bulk-deletes them (chunked under the 500-write batch limit).

## 8. Languages and theme

- Localization via `flutter_localizations` + ARB files under `lib/l10n/`
  (`app_ar.arb` is the template): **Arabic, French, English**, each with the same
  **312 message keys** (`l10n.yaml`; regenerate with `flutter gen-l10n`).
- Arabic is the default language on first launch; the app is RTL-aware.
- Theme: Material 3, brand green `#2E7D32`, with light, dark and system modes.
- Both preferences are stored locally with `shared_preferences`
  (`AppSettings`, keys `ui_locale` and `ui_theme_mode`) and applied live through
  `ValueNotifier`s; the UI language also drives date formatting
  (`initializeDateFormatting` + `Intl.defaultLocale`).

## 9. Pagination, loading and states

Reads are kept proportional to what the user actually looks at — important on the
Firestore free tier (50K reads/day). The pattern is a **live head page plus
one-shot older pages**, implemented once in `PagedList<T>`
(`lib/state/paged_list.dart`) and reused everywhere:

- **`PagedList<T>`** subscribes to a **live first page** of `kPageSize = 20`
  documents (re-emits on server changes so new posts appear without a refresh)
  and loads older pages on demand with `startAfterDocument` via the "المزيد"
  (load more) button. It de-duplicates head/tail overlap by document id, supports
  optimistic `remove` after a delete, and re-subscribes on refresh/filter change.
- **Every list uses it** (or the same head+tail shape): the give feed, the ask
  board, the blood board, "إعلاناتي", "محجوزاتي", "طلباتي", and all five admin
  tabs. Older pages are fetched one-shot, so scrolling costs one query per page
  instead of a permanent listener over the whole collection.
- **Search is Firestore-native** for listings: each document stores a `keywords`
  array containing every word plus every prefix of every word (normalised:
  lowercased, tashkeel stripped, alef/hamza/teh-marbuta unified, tokens capped at
  16 chars). The query uses `arrayContainsAny` on the query words and then
  AND-filters on the client, so partial words match and multi-word queries require
  every word. `keywords` is bounded to 3000 entries (asserted by tests against the
  rules cap).
- **Board search is client-side** (substring/AND over the pages already loaded),
  unlike the listings feed which is indexed server-side — see §14.
- **First-load state** uses shimmering **skeletons** shaped like the real cards
  (`lib/widgets/skeletons.dart`), then `EmptyView` / `ErrorView` with
  pull-to-refresh and retry once data or an error arrives (`lib/widgets/state_views.dart`).
- **Firestore composite indexes** for the ordered/paginated queries and feed
  filters live in `firestore.indexes.json` (deploy: §11, §13).

## 10. Tech stack and architecture

| Layer | Choice |
|---|---|
| Mobile app | Flutter 3.29.0 (Dart 3.7.0), Material 3, Android-first; RTL/LTR |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore |
| Images | Base64 inside Firestore (see §6) |
| Security | Firestore Security Rules (server-enforced) |
| Geography | Local static dataset: 58 wilayas + 1527 communes (no maps/API) |
| State | `StatefulWidget` + streams + `ChangeNotifier`/`ValueNotifier` (no state-management package) |
| Paging | `PagedList<T>` (live head + one-shot tail) in `lib/state/` |

Architecture is exactly `Flutter → Firebase`, with all Firebase-specific code
isolated in `lib/services/`. Dart dependencies: `firebase_core ^3.8.0`,
`firebase_auth ^5.3.0`, `cloud_firestore ^5.4.0`, `google_sign_in ^7.2.0`,
`image_picker ^1.2.1`, `image ^4.10.1`, `intl ^0.19.0`,
`shared_preferences ^2.3.0` (dev: `flutter_lints ^5.0.0`,
`flutter_launcher_icons ^0.14.4`).

```
lib/
  main.dart              # Firebase init, locale/theme, AuthGate
  firebase_options.dart  # generated by FlutterFire CLI (public identifiers)
  models/                # AppUser, Listing, RequestPost, Report
  services/              # auth, user, listing, request, image, report, admin,
                         # paging (QueryPage)
  screens/               # auth, home, listing, requests, my_listings, profile,
                         # onboarding, admin
  widgets/               # listing/request cards, base64 image, skeletons,
                         # publish sheet, state views, location chips,
                         # wilaya+commune fields, social sign-in
  state/                 # paged_list (PagedList), app_settings (locale+theme)
  data/algeria_data.dart # 58 wilayas -> communes (static)
  l10n/                  # app_ar.arb (template), app_en.arb, app_fr.arb + gen/
  theme/app_theme.dart   # design tokens
  utils/                 # constants, labels, formatters, errors, search, cache,
                         # google_auth
test/                    # 13 files, 89 tests
firestore.rules          # deployed security rules
firestore.indexes.json   # composite indexes
android/key.properties   # release signing — NOT committed (gitignored)
```

## 11. Firebase setup and configuration

- **Project:** `ta3awen-mvp-5a5ea` (display name `ta3awen-mvp`), region `nam5`.
- **Android app id:** `1:72351529323:android:74267d87b552636433b42e`.
- **Config files (committed — public identifiers only):**
  `android/app/google-services.json` and `lib/firebase_options.dart`.
- **Firestore:** default database in production mode (closed by default); access
  is governed entirely by `firestore.rules`, deployed with
  `firebase deploy --only firestore:rules`. The composite indexes for
  ordered/paginated queries are deployed with
  `firebase deploy --only firestore:indexes` (or both at once with
  `firebase deploy --only firestore`).
- **Free tier only:** no paid services are used.

### Manual steps still required (browser, ~5 minutes)

**1. Enable Email/Password sign-in** — required before anyone can register.
Firebase refused API-based creation of the auth configuration for the project
(`CONFIGURATION_NOT_FOUND`, billing-gated `initializeAuth`), so this is done once
in the console:

1. Open https://console.firebase.google.com → project **ta3awen-mvp-5a5ea**
2. **Build → Authentication → Get started**
3. **Sign-in method → Email/Password → Enable → Save**

**2. Enable Google sign-in (for "Continue with Google"):**

1. Same **Authentication → Sign-in method** screen → **Google → Enable**.
2. **Project settings → Your apps → Android app** → add the **SHA-1** (and
   **SHA-256**) fingerprint of the certificate you sign with (debug keystore for
   local testing, the release `ta3awen-upload.jks` for releases).
3. The OAuth client IDs are already present in the committed
   `android/app/google-services.json` / `lib/firebase_options.dart`.
   A missing/incorrect SHA-1 surfaces as `INVALID_CLIENT_APPLICATION`, which the
   app maps to a configuration hint.

**3. Grant yourself admin (after your first registration):**

1. Register an account in the app (account #1).
2. Firebase Console → **Firestore → users** → copy the document ID (= your UID).
3. Create collection **`admins`** → document ID = that UID → any field
   (e.g. `role: "admin"`).
4. Restart the app → Profile → **لوحة الإدارة** appears.

The first admin must be seeded here (console / Admin SDK). After that, existing
admins can grant or revoke membership **from the in-app panel**
(`AdminService.setAdmin`), which the rules permit (see §12).

## 12. Firestore security rules and authorization model

The rules are the source of truth for authorization; the UI only reflects them.
There is **no** `allow read, write: if true` anywhere.

Helpers: `signedIn()`, `isAdmin()`, `postCountOk()`, `requesterDisabled()`,
`canWrite()` (= signed in and not disabled), `validListing()`, `ownerListing()`,
`validRequest()`, `kBloodTypes()`, `requestKindEditAllowed()`.

**Rules vs. automated tests.** The model below is what `firestore.rules` enforces
in production. The repository's committed tests (`test/`) do **not** exercise the
rules — they cover client-side logic only. The rules were checked during
development with an emulator-based rules suite kept **outside** this repository, so
the behaviours described here should be read as **implemented but not
automatically re-verified inside this repo**.

| Collection | Read | Write |
|---|---|---|
| `users/{uid}` | owner or admin | create self (hasOnly allow-list, `disabled == false`); update self limited to name/wilaya/commune/phone (`disabled` immutable); admin may update/delete |
| `admins/{uid}` | self or admin | admin only (`allow write: if isAdmin()`) — lets the panel grant/revoke membership; non-admins are still blocked |
| `stats/{uid}` | self or admin | create self with `postCount == 1`; update self with exactly `+1`; delete admin |
| `listings/{id}` | any signed-in | owner create (validated, `postCountOk`, status `متاح`, server timestamps, no claim keys); owner/claimant update paths + admin; delete owner/admin |
| `listings/{id}/images/{0..4}` | any signed-in | owner (or admin) only; `index 0…4` must equal the doc id; `data < 900000` |
| `requests/{id}` | any signed-in | author create (validated, `postCountOk`, status `open`, server timestamps, no match keys); owner content edit / toggle, match by a non-author, release by matcher/author, finalise by author; delete author/admin |
| `reports/{id}` | admin only | any non-disabled signed-in user may create (hasOnly allow-list, `reporterId == uid`, reason ∈ fixed enum, `createdAt == request.time`); admin update/delete |

**Status lifecycles enforced server-side**

- Listings: `متاح --claim--> محجوز --owner confirms--> تم التبرع به`;
  `محجوز --cancel--> متاح`; owner may also go `متاح ↔ تم التبرع به`. A reservation
  can never be left by simply flipping `status`.
- Requests: `open --match--> matched`; `matched --release(matcher/author)--> open`;
  `matched --finalize(author)--> closed`; `open ↔ closed` by the author.

**Anti-spam:** `postCountOk()` requires `stats/{uid}.postCount < 100` for each
listing/request create (a lifetime cap of 100 posts per account).

## 13. Install, run, test, and build

**Requirements:** Flutter 3.29.0 (Dart 3.7.0), JDK 17, Android SDK 35
(`minSdk 23`), Gradle 8.10.2 / AGP 8.7.0 / Kotlin 1.8.22.

```bash
flutter pub get
flutter gen-l10n                             # regenerate localized strings
flutter run                                   # device/emulator with USB debugging

flutter analyze                               # static analysis
flutter test                                  # unit + widget tests

# push rules + indexes to the Firebase project
firebase deploy --only firestore:rules,firestore:indexes

# universal APK (large)
flutter build apk --release

# recommended: small per-CPU APKs (produces arm64-v8a / armeabi-v7a / x86_64)
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/flutter-apk/`. The arm64-v8a build is the one to
install on almost every modern phone; the armeabi-v7a build targets older/32-bit
devices; x86_64 covers emulators. On low-memory machines the Gradle daemon is
capped at `-Xmx4G` in `android/gradle.properties`.

**Release signing:** `android/key/ta3awen-upload.jks` plus `android/key.properties`
(the password lives in `key.properties`). **Both are gitignored and must never be
committed** — back them up safely; losing them means you can never publish an
update to Google Play under the same identity (sideloaded installs are
unaffected). When `key.properties` is absent the release build falls back to the
debug signing config.

## 14. Limitations and known issues

- **No closed-app push notifications.** True push needs Cloud Functions + FCM
  (Blaze/billing), which this project avoids; the free-tier alternative is a
  scheduled local-notification poll, not yet implemented.
- **Board and admin search are client-side** (substring/prefix over the pages
  already loaded), unlike the listings feed which is indexed server-side. Filters
  that map to a Firestore field are applied server-side first.
- **Admin lists paginate but never bulk-export** — there is no "count matched by
  search" and no full-collection export; counts on the dashboard come from
  aggregations, not the filtered lists.
- **Base64 images in Firestore** are simple and free-tier friendly, but documents
  are large and reads/bandwidth are heavier than Cloud Storage would be.
- **Phone exposure trade-off:** `contactPhone` on listings and requests is
  readable by any signed-in user (the app relies on phone contact since there is
  no chat). User profile documents themselves are owner/admin only. This is a
  deliberate product decision worth revisiting under a privacy review.
- **Anti-spam cap caveat:** the `stats` counter is maintained by the client in
  the same batch as the create, and the rule reads the pre-batch snapshot — a
  determined client batching creates could start from a stale value and slightly
  exceed 100. Server-side enforcement (Cloud Functions) would close this.
- **No account deletion or privacy policy** yet (useful before any public launch).
- **iOS is not configured** — the project is Android-first.
- **Seed/demo data:** listings whose ID starts with `seed-` may exist in the
  database; the admin dashboard can bulk-delete them.
- **Manual verification pending:** the automated tests cover pure logic (search,
  model shapes, constants, rules caps), the pagination controller, error mapping
  and widget renders; the Firebase-backed flows (register/login, listing/request
  create, admin actions) still require a live project with the manual steps in
  §11 and a device/emulator.

## 15. Backup and recovery

- **Signing material:** back up `android/key/ta3awen-upload.jks` and
  `android/key.properties` somewhere safe and offline. Without them the app
  cannot be updated on Google Play under the same identity.
- **Firestore data:** use a Firestore export (`gcloud firestore export` or the
  console export to a Cloud Storage bucket) to snapshot the database. Note that
  scheduled/managed backups are a Blaze feature; a manual export works on the
  free tier. Seed/test data can always be regenerated.
- **Secrets:** never commit `android/key.properties`, `android/key/`, `*.jks` /
  `*.keystore`, or any service-account JSON. `google-services.json` and
  `lib/firebase_options.dart` **are** committed intentionally — they contain only
  public identifiers (project id and the public API key shipped inside every
  APK).

## 16. Development status

**Status: working MVP/prototype — not production-ready.** The core user journeys
are implemented, static analysis is clean and the logic tests pass, but the
Firebase-backed flows have not been automatically verified and several
launch-blockers remain (see §14).

Evidence from this checkout:

- `flutter analyze` → **No issues found!**
- `flutter test` → **89 tests, all passing**, across 13 files:
  - `test/ta3awen_test.dart` — Algeria data, categories/conditions, status & type
    constants, model shape and `toMap` allow-lists, reservation/match flags.
  - `test/search_keywords_test.dart` — normalisation, tokenisation and keyword caps.
  - `test/request_filters_test.dart`, `request_kind_switch_test.dart`,
    `request_match_labels_test.dart`, `listing_kind_test.dart` — request/listing
    filtering, the kind switch and match-label logic.
  - `test/paged_list_test.dart` — `PagedList` head load, load-more, de-duplication,
    error propagation and the load-more footer.
  - `test/auth_error_mapping_test.dart`, `social_sign_in_widgets_test.dart` —
    auth-error → localized message mapping and the Google sign-in widgets.
  - `test/ui_polish_test.dart`, `listing_card_layout_test.dart`,
    `request_card_layout_test.dart`, `publish_sheet_test.dart` — skeletons, card
    layouts (with/without image) and the publish sheet.
- **Automated outside this repo:** the Firestore security rules were checked with
  an emulator-based rules suite kept outside the repository; it is not run by
  `flutter test`.
- **Manually verified in an earlier session, not re-run here:** the release APK
  build and its signature.
- **Not automated — requires a device and a live Firebase project:** registration,
  login, listing/request create-edit-reserve, and admin actions.
- Git: branch `main`. Recent history covers the design overhaul, live feed +
  server-side search, reservations, the requests board, blood donations, the
  admin overhaul, onboarding/profile editing, the anti-spam cap, the
  **pagination + admin-console rework**, **product-UI polish** (skeletons,
  placeholders, page transitions) and **Continue with Google** sign-in.

### Prioritized remaining work

1. **Enable Email/Password + Google auth and create the first admin** on the
   target Firebase project (§11) — without this, registration/sign-in does not work.
2. **Add account deletion and a privacy policy** — required before any public or
   store release.
3. **Decide and implement a notification strategy** (no closed-app push on the
   free tier today).
4. **Enforce the anti-spam cap server-side** to close the batched-create caveat
   (§14), e.g. via Cloud Functions once billing is acceptable.
5. **Move the rules test suite into the repo** so the security protections are
   re-verified automatically.
6. **Consider migrating images to Cloud Storage** if/when Blaze is acceptable
   (§6).
7. **iOS support** — the project is Android-only today.

### Distribution

- Source: https://github.com/MoIslam-Dev/ta3awen (branch `main`).
- Release APKs and PDF notes: https://github.com/MoIslam-Dev/ta3awen-apk
  (latest release [`v6`](https://github.com/MoIslam-Dev/ta3awen-apk/releases/tag/v6);
  each release ships `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk` and
  `app-x86_64-release.apk`).

---

Free Firebase tier only. Do not commit `android/key.properties`, `android/key/`,
or any service-account JSON.
