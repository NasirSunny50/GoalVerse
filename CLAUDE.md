# CLAUDE.md

Guidance for working in this repository.

## Project

`fifa_world_cup_2026` — a premium Flutter companion app for the FIFA World Cup
2026. Feature-first architecture, `provider` for state, Material 3 light/dark
themes. Flutter 3.41 / Dart 3.11.

## Commands

```bash
flutter pub get
flutter analyze          # keep this clean — zero issues expected
flutter test
flutter run -d chrome    # quick visual check on web
flutter build apk        # Android release artifact
```

## Layout

- `lib/data/` — models, static sources (`teams_data.dart`, `venues_data.dart`,
  `schedule_data.dart` = the **real 104-fixture schedule**), and `FixturesRepository`
  which assembles matches (converting venue-local kick-offs to UTC), simulates
  results for already-played games, and computes standings. Single place to swap in
  a live API later.
- **Time zone:** kick-offs are stored as UTC; display uses Bangladesh time
  (`match.kickoffBd`, UTC+6) with stadium-local available via `match.kickoffLocal`.
  Date grouping/"today" use `FixturesProvider.nowBd`. Status/countdown math uses the
  absolute UTC `kickoff` vs `DateTime.now()`.
- `lib/providers/` — `AppState` (theme, favourites, onboarding; persisted via
  shared_preferences) and `FixturesProvider` (1-second clock + match queries).
- `lib/core/` — theme (`AppColors`, `AppTheme`, `context.semantic`/`scheme`/`texts`
  extensions), shared widgets (`GlassCard`, `MatchCard`, `TeamBadge`, `StatusPill`,
  `GradientScaffold`, `SectionHeader`), and date helpers.
- `lib/features/<feature>/` — one folder per screen/area.

## Conventions

- Use the existing core widgets and the `context.semantic` / `context.scheme` /
  `context.texts` extensions instead of hard-coding colours/styles.
- Colours use `withValues(alpha:)` (Flutter ≥3.27), not the deprecated
  `withOpacity`.
- Match status is derived at render time from `FootballMatch.statusAt(now)` using
  the live clock — never store a static status.
- Results are simulated deterministically from team ratings in
  `FixturesRepository` for any match before `now`; keep new logic deterministic so
  standings/brackets stay stable within a session.
- Team "flags" are rendered as colour-coded code badges (`TeamBadge`) for
  cross-platform consistency. Emoji flags exist on the model but aren't relied on.

## Gotchas

- The 1-second ticker in `FixturesProvider` means the app never goes render-idle;
  idle-based screenshot tools may time out even though the app is healthy.
- `GradientScaffold` exposes `appBar`, `body`, `floatingActionButton`,
  `bottomNavigationBar` — it has no `floatingActionButtonLocation`.
