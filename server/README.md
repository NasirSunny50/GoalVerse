# GoalVerse Backend

A Dart [`shelf`](https://pub.dev/packages/shelf) server that powers the entire
GoalVerse **Compete** system: accounts, predictions, scoring and leaderboards.
Pure Dart (no extra runtime), JSON file storage — runs on your PC.

## Run it

```bash
cd server
dart pub get          # first time only
dart run bin/server.dart
```

It listens on **http://localhost:8787** (set `PORT` to change it). On start it
loads `data/fixtures.json` and begins polling TheSportsDB for real results.

## Run the app against it

The Flutter app defaults to `http://localhost:8787`. Run it on the same PC:

```bash
flutter run -d windows        # or: flutter run -d chrome
```

To point the app at a different host (e.g. the phone reaching your PC over LAN):

```bash
flutter run --dart-define=API_BASE=http://192.168.1.50:8787
```

## Tests

```bash
cd server && dart test                       # backend unit tests
flutter test test/live_integration.dart      # app client vs the live server
```

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET  | `/health` | – | liveness |
| POST | `/auth/register` | – | start sign-up (sends OTP — demo code **123456**) |
| POST | `/auth/verify-otp` | – | verify OTP → creates account + token |
| POST | `/auth/login` | – | email + password → token |
| GET  | `/me` | Bearer | profile + stats |
| GET  | `/stats` | Bearer | stats only |
| GET  | `/predictions` | Bearer | match + tournament predictions |
| PUT  | `/predictions/match/<id>` | Bearer | save a match prediction (locks at kick-off) |
| PUT  | `/predictions/tournament` | Bearer | save tournament picks (locks at the Final) |
| GET  | `/leaderboard?period=global\|weekly\|monthly\|allTime` | optional | ranked board |
| GET  | `/fixtures` | – | the schedule |
| GET  | `/tournament/result` | – | the recorded final outcome (`decided`/`graded` flags + team ids) |
| GET  | `/admin/results` | Admin | every fixture + its admin-entered result |
| PUT  | `/admin/result/<id>` | Admin | record/overwrite a match's real result |
| DELETE | `/admin/result/<id>` | Admin | clear a match's result |

## Scoring is admin-driven — no live data

Predictions are scored **only** against results the **admin** records. There is
**no dependency on any live feed** (TheSportsDB proved unreliable, e.g.
mislabeling cards). A match stays **unscored** until the admin enters its result.

The admin signs in on the **same login screen** with the hardcoded credentials
**admin@gmail.com / Admin@123** (override via `GV_ADMIN_EMAIL` /
`GV_ADMIN_PASSWORD`). The server returns `isAdmin:true` and the app routes to the
in-app **Admin Panel**, where the admin sets each match's winner / score /
first-scorer / MOTM / red-card. Admin authority is enforced server-side; the
admin email is reserved and cannot register or make predictions.

`data/fixtures.json` is exported from the app's engine (regenerated on every
`flutter test`) so match IDs match on both sides.

## Database

Storage is **SQLite** at `data/goalverse.db` (the bundled `sqlite3.dll` is used
by the Dart server). Real tables:

| Table | Holds |
|---|---|
| `users` | email, name, employee_id, **salted SHA-256** pw_hash, salt, created_at |
| `sessions` | bearer token → email |
| `match_predictions` | email, match_id, winner, scores, first_scorer, motm, red_card |
| `tournament_predictions` | email, winner / runner-up / golden boot / golden glove |

**View the tables** (any of these):

```bash
cd server
dart run bin/dbview.dart      # prints every table + rows, no install needed
```

…or open `server/data/goalverse.db` in a GUI — **DB Browser for SQLite**
(https://sqlitebrowser.org), DBeaver, or the VS Code "SQLite" extension.

**Reset everything** (wipe all accounts & predictions, keep the schema):

```bash
cd server && dart run bin/reset_db.dart
```

## Tournament scoring (champion / runner-up / golden boot / golden glove)

Per-match predictions are graded automatically as matches finish. The
**tournament-long** markets (Winner +50, Runner-up +30, Golden Boot +20,
Golden Glove +20 — each predicted as a **team id**) are graded only once you
record the real outcome **after the Final**.

Nothing is awarded until then: the result lives in
`data/tournament_result.json` and defaults to *undecided*. Points are
double-gated — they require both `decided: true` **and** the Final's kick-off to
be in the past — so a result entered early can never pay out before the Final.

```bash
cd server
dart run bin/set_result.dart                       # show the current result
dart run bin/set_result.dart --champion arg --runner-up fra \
    --golden-boot arg --golden-glove fra            # record it
dart run bin/set_result.dart --clear                # wipe (back to undecided)
```

The running server picks up the file on its next scoring pass — **no restart
needed**. Team ids are the lower-case ids used in predictions (`arg`, `fra`, …).
A user's tournament points fold into their total points, leaderboard and rank
exactly like match points; `/stats` also returns a `tournamentPoints` field.

## Rival bots

The leaderboard can include 40 simulated rivals for a livelier competition.
They are **off by default**; enable with an env var:

```bash
set GV_BOTS=1 && dart run bin/server.dart      # Windows
```
