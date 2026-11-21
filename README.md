# ASAH · Juta Berlian Culinary

Training with mentorship (**Asuh**), daily SOP tasks (**Aksi**) and monitoring (**Standar**) for
Juta Berlian Culinary's outlets, in one Flutter codebase:

| Entry point | Who | Runs on |
| --- | --- | --- |
| `lib/main.dart` | Staff, trainees, mentors, outlet managers, area managers | Android, iOS |
| `lib/main_admin.dart` | HQ admin, HQ trainer, training manager, HR and senior management (and managers' dashboards) | Web |

Backend: Supabase (Postgres + RLS + RPCs, Auth with phone OTP, Storage, Edge Functions, Realtime).
Videos: Cloudflare Stream. Push: OneSignal.

## Project layout

```
lib/
  main.dart, main_admin.dart     entry points
  app/                           mobile app shell, router, role-based tabs
  admin/                         admin web: shell, router, pages/
  core/                          config, theme, l10n, offline store, media, shared widgets
  features/
    session/                     profile + permissions (mirrors app.has_permission)
    auth/                        phone + OTP sign in
    today/                       staff Today, outlet manager Today
    checklists/                  fill (photos, location, drafts), run results
    sync/                        offline outbox, replayed when back online
    learning/                    path, module (video / SOP / PDF), quiz, practical recording
    mentorship/                  mentor dashboard, scoring, check-ins, rating
    issues/                      list, detail + timeline, raise
    team/ area/                  outlet manager team, area dashboard and audits
    notifications/ profile/
  l10n/app_en.arb, app_id.arb    English and Bahasa Indonesia (PRD F8)
supabase/
  migrations/20261118000000_asah_mvp_schema.sql   the schema (unchanged from database_mvp)
  migrations/20261121000000_app_support.sql       additions the app needs, see below
  functions/                     stream-upload, stream-playback, stream-webhook, admin-users, push
  tests/                         behaviour tests for plain Postgres (from database_mvp)
  bootstrap_first_admin.sql, seed_example.sql
```

### Architecture

Compared with arkpadel (feature folders, `setState`, a global Supabase client), this app keeps the
good parts (`core/` + `features/`, `AppConfig` via `--dart-define-from-file`, OneSignal push through a
DB-triggered Edge Function) and adds what five roles and offline work need:

- **Riverpod** for dependency injection and async state; every screen reads a provider, so data is
  cached, refreshable and testable.
- **go_router** with an auth redirect; home tabs are built from the person's permissions.
- **Repositories** per feature wrap Supabase. The server stays the authority (PRD R6): RLS and
  `SECURITY DEFINER` RPCs check every action, the app only hides what would be refused
  (`Session.can()` mirrors `app.has_permission()`).
- **Offline (F7)**: session, today's runs, checklist items, modules and lessons are cached on the
  phone; checklist answers are saved as drafts on every tap (A6); submissions and lesson progress go
  to an outbox (`features/sync`) that replays when the connection returns. Lesson videos can be
  downloaded for offline viewing.

## Setup

### 1. Supabase

```bash
supabase link --project-ref <ref>
supabase db push                     # both migrations
```

Then in the dashboard:

1. **Database › Extensions**: enable `pg_cron` (and `pg_net`, which the second migration also enables).
   Run the `cron.schedule` lines at the end of both migrations (daily runs, missed checklists,
   escalation, certificate reminders, due reminders, check-in reminders, trainees behind).
2. **Authentication › Providers › Phone**: enable it and connect an SMS provider (Twilio, Vonage,
   MessageBird...). For development, add test numbers with fixed OTPs. Sign-ups stay off:
   accounts are created by HQ.
3. **First admin**: add a user with a phone in Authentication › Users, then run
   `supabase/bootstrap_first_admin.sql` with that phone.
4. Optional: run `supabase/seed_example.sql` for an example outlet, checklist, module and path.

### 2. Cloudflare Stream

Create an API token with *Stream: Edit*. Find the customer code in any Stream video URL
(`https://customer-<code>.cloudflarestream.com/...`). Videos are uploaded with *signed URLs
required*, so only people whose `media_files` row passes RLS get a playback token.

```bash
supabase secrets set \
  CLOUDFLARE_ACCOUNT_ID=... CLOUDFLARE_STREAM_API_TOKEN=... CLOUDFLARE_STREAM_CUSTOMER_CODE=... \
  ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=... PUSH_HOOK_SECRET=<random>

supabase functions deploy stream-upload stream-playback admin-users
supabase functions deploy stream-webhook push --no-verify-jwt
```

Register the webhook (store the returned secret as `CLOUDFLARE_STREAM_WEBHOOK_SECRET`):

```bash
curl -X PUT "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT/stream/webhook" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"notificationUrl":"https://<ref>.supabase.co/functions/v1/stream-webhook"}'
```

### 3. Push (OneSignal)

Create a OneSignal app (FCM for Android, APNs for iOS), then store the push hook in Vault so the
`notifications_push` trigger can call the `push` function:

```sql
select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_hook_url');
select vault.create_secret('<same value as PUSH_HOOK_SECRET>', 'push_hook_secret');
```

Until then notifications still appear in the in-app inbox.

### 4. Run

```bash
cp config/example.json config/development.json   # fill in URL, anon/publishable key, OneSignal app id
flutter pub get

flutter run --dart-define-from-file=config/development.json                              # phone
flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=config/development.json  # admin web

flutter build web -t lib/main_admin.dart --dart-define-from-file=config/production.json
flutter test
```

## What the second migration adds

`20261121000000_app_support.sql` leaves the original schema untouched and adds:

| Gap found | Fix |
| --- | --- |
| A trainee could not read their mentor's profile, so "Your mentor" had no name | Policy `trainee reads own mentor` |
| Staff could not see colleagues' names in issue timelines without `user.view` | RPC `people_names(ids)`, limited to people the caller works with |
| Area managers (no outlet of their own) could not upload audit photos | Policy `upload media for outlets in scope` |
| No storage bucket for photos and PDFs | Private bucket `asah-media`; reading an object requires reading its `media_files` row |
| A2, M3 and M4 reminders were not scheduled | `app.remind_due_checklists`, `app.remind_mentor_checkins`, `app.escalate_behind_trainees` |
| `notifications` rows never reached phones | Trigger → `pg_net` → `push` Edge Function → OneSignal; Realtime for the inbox badge |

## PRD coverage

| Area | Requirements | Where |
| --- | --- | --- |
| Foundation | F1 one codebase, F5 phone OTP, F7 offline, F8 EN/ID | `main.dart` / `main_admin.dart`, `features/auth`, `features/sync`, `lib/l10n` |
| | F2 departments, positions, levels · F3 outlets · F4 users + spreadsheet import · F9 audit log | admin `org_page`, `outlets_page`, `users_page` + `admin-users` function, `audit_log_page` |
| | F6 push | `notifications_push` trigger, `push` function, `PushService` |
| Roles | R1–R5 permission matrix, scoped grants, custom roles, sensitive marking | admin `roles_page`, roles dialog in `users_page` |
| | R6 server checks everything · R7 separation of duties · R8 deactivation | schema RLS/RPCs; app hides refused actions |
| Asuh training | T1 module builder, T2 quiz + question bank, T3 practical test, T4 review, T5 versions + retraining | admin `module_builder_page`; phone `module_screen`, `quiz_screen`, `practical_record_screen` |
| | T6 paths, T7 auto-assign, T8 certificates, T9 refresher, T10 my path | admin `paths_page`; DB triggers; phone `learn_screen`, `certificates_screen`, issue/staff detail |
| Asuh mentorship | M1 assign with eligibility, M2 dashboard, M3 check-ins, M4 alerts, M5 end, M6 spot checks, M7 anonymous rating | `team/`, `mentorship/`, admin `mentor_ratings_page` |
| Aksi | A1 template builder, A2 schedules + reminders, A3 camera-only photos + time + location, A4 issues from failed items, A5 missed alert, A6 drafts, A7 manager view | admin `checklist_builder_page`; phone `checklist_fill_screen`, `manager_today_screen` |
| Standar | S1 issue tracker, S2 accept/reopen, S3 escalation, S4 audits + dashboards, S5 trends + CSV | phone `issues/`, `area/`; admin `dashboard_page`, `issues_page` |

## Known gaps and next steps

- The **admin web is in English**; the phone app is fully in English and Bahasa Indonesia.
- **Server time on offline submissions**: a checklist filled offline is stamped with the server time
  when it syncs (the answers keep the time they were given). If it syncs after the run was marked
  missed, the server refuses it and the person sees why.
- **Quizzes need a connection**: grading is server side by design, so answers never reach the phone.
- **Large training videos** upload in one request from the browser (fine up to ~200 MB). Use
  Cloudflare's tus upload for longer videos.
- SQL behaviour tests in `supabase/tests` need a plain Postgres (`psql -f`); they were not run here.
- Product knowledge (waiting for the client's material) and Hebat are out of this MVP.
