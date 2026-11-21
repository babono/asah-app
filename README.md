# asah-app · ASAH phone app

Flutter app (Android and iOS) for Juta Berlian Culinary's outlet people: training with mentorship
(**Asuh**), daily SOP tasks (**Aksi**) and monitoring (**Standar**).

| Repo | What |
| --- | --- |
| **asah-app** (this) | Phone app for staff, trainees, mentors, outlet managers and area managers |
| [asah-be](https://github.com/babono/asah-be) | Supabase backend: schema, RLS, RPCs, Edge Functions (Cloudflare Stream, push, user creation) |
| [asah-admin](https://github.com/babono/asah-admin) | Web admin for HQ: setup, modules, paths, checklist templates, dashboards |

## What each role gets

Tabs come from the person's permissions (`rpc('my_permissions')`):

| Role | Tabs |
| --- | --- |
| Staff / trainee | Today · Learn · Issues · Me |
| Mentor (added to staff) | Today · Learn · Mentor · Issues · Me |
| Outlet manager | Today (outlet) · Issues · Team · Me |
| Area manager | Outlets · Issues · Audits · Me |

- **Today**: checklists due this shift, learning path, mentor (design screen 1).
- **Checklists**: yes/no, number with range, note and photo items; photos from the in-app camera
  only; time and location stamped on submit, refused outside the outlet; a "no" or out-of-range
  answer warns that it raises an issue. Answers are saved as a draft on every tap (A3, A4, A6).
- **Learning**: path by day 1 / week 1 / month 1, lessons (Cloudflare Stream video, SOP card, PDF),
  quiz graded on the server, practical test recorded in the app, certificates (T1–T3, T8, T10).
- **Mentor**: trainees with progress and alerts, score practical tests per rubric line, weekly
  check-ins, own average rating after 3 ratings (M2–M4, M7).
- **Outlet manager**: today's checklists by shift, open issues, trainees behind; assign issues,
  accept or reopen fixes, assign mentors and refresher modules, spot-check sign-offs (A7, S1, S2,
  M1, M5, M6, T9).
- **Area manager**: outlets with on-time %, issues and training; escalated issues; visit audits (S3, S4).
- **Bahasa Indonesia and English** (F8), **push notifications** (F6), **offline** (F7).

## Project layout

```
lib/
  main.dart
  app/            app shell, router, role-based tabs
  core/           config, theme, l10n, offline store, media (Storage + Cloudflare Stream), widgets
  features/
    session/      profile + permissions; Session.can() mirrors app.has_permission()
    auth/         phone + OTP sign in
    today/        staff Today, outlet manager Today
    checklists/   fill, drafts, run results
    sync/         offline outbox, replayed when back online
    learning/     path, module, quiz, practical recording
    mentorship/   mentor dashboard, scoring, check-ins, rating
    issues/       list, detail + timeline, raise
    team/ area/   outlet team, area dashboard, audits
    notifications/ profile/
  l10n/           app_en.arb, app_id.arb
test/
```

### Architecture

- **Riverpod** for dependency injection and async state; **go_router** with an auth redirect.
- **Repositories** per feature wrap Supabase. The server is the authority (PRD R6): RLS and
  `SECURITY DEFINER` RPCs in asah-be check every action; the app only hides what would be refused.
- **Offline**: session, today's runs, checklist items and modules are cached on the phone.
  Checklist submissions and lesson progress go to an outbox (`features/sync`) that replays when the
  connection returns. Lesson videos can be downloaded.

## Run

Set up the backend first (see asah-be). Then:

```bash
cp config/example.json config/development.json   # Supabase URL + anon/publishable key, OneSignal app id
flutter pub get
flutter run --dart-define-from-file=config/development.json
flutter test
```

Push needs a OneSignal app (FCM for Android, APNs for iOS); leave `ONESIGNAL_APP_ID` empty to run
without it. The app links the device to the Supabase user id as the OneSignal External ID.

## Known gaps

- A checklist filled offline is stamped with the server time when it syncs. If it syncs after the
  run was marked missed, the server refuses it and the person sees why.
- Quizzes need a connection: grading is server side, so answers never reach the phone.
- Not yet run against a live Supabase project; iOS not built yet.
