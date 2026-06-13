# FIFA World Cup 2026 — Companion App ⚽

A premium, modern Flutter app to track every fixture, team, venue and storyline of
the FIFA World Cup 2026. Built to feel like a polished sports product, not a plain
fixture list — glassmorphism, gradient accents, smooth micro-interactions, and a
live, ticking experience throughout the tournament.

> Hosts: 🇺🇸 USA · 🇨🇦 Canada · 🇲🇽 Mexico — 48 teams, 12 groups, 16 host cities, 104 matches.

## ✨ Features

- **Smart Home Hub** — live blockbuster countdown banner, tournament progress
  pulse, live-now matches, today's fixtures, personalised "Your Teams" feed,
  quick filters and a host-city rail.
- **Fixture Explorer** — full 104-match schedule, filter by stage
  (Groups → R32 → R16 → QF → SF → Final) and by national team, grouped by day.
- **Match Details** — win-probability model, head-to-head bars, generated match
  timeline, venue link and full match info.
- **Teams** — all 12 group standings (auto-computed from results) plus a searchable
  nations list with favourites.
- **Team Dashboard** — per-nation stats, upcoming matches, recent results and a
  shortcut into the Road to the Final.
- **Calendar** — monthly view with match-day indicators and a day-by-day fixture
  list.
- **Explore** — interactive host-cities map (tap a pin for matches), a Stadium
  Explorer grid, and the Road to the Final entry point.
- **🛣️ Road to the Final** *(signature feature)* — pick any nation and see a visual
  bracket of the **possible opponents** it could face at each knockout round on the
  projected path to the trophy.
- **Fan Mode onboarding** — choose favourite nations up front; the whole app
  personalises around them.
- **Premium dark & light themes** with one-tap toggle, persisted offline.

## 🏗️ Architecture

Feature-based, scalable structure:

```
lib/
├── main.dart                # Entry + provider wiring
├── app.dart                 # MaterialApp, theming, onboarding gate
├── core/
│   ├── theme/               # Colors, Material 3 light/dark themes
│   ├── utils/               # Date/time formatting
│   └── widgets/             # GlassCard, MatchCard, TeamBadge, StatusPill, …
├── data/
│   ├── models/              # Team, Venue, FootballMatch, Standing
│   ├── sources/             # 48 teams, 16 venues (static data)
│   └── repositories/        # FixturesRepository — generates the 104-match schedule
├── providers/               # AppState (theme/favorites), FixturesProvider (clock)
└── features/
    ├── onboarding/  home/  fixtures/  match_details/
    ├── teams/  calendar/  venues/  explore/  road_to_final/  shell/
```

- **State management:** `provider` (`ChangeNotifier`).
- **Persistence / offline:** `shared_preferences` (theme, favourites, onboarding).
- **Live experience:** `FixturesProvider` ticks every second so countdowns and
  live states stay current. Results are **simulated deterministically** for any
  match whose kickoff is in the past relative to the device clock, so the app feels
  live from the opening match through the final.
- **API-ready:** swap `FixturesRepository`'s static generation for a remote source
  without touching the UI layer.

## 🚀 Run

```bash
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # web
flutter build apk      # Android
```

## 🧪 Tests

```bash
flutter test
```

Covers dataset integrity (48 teams / 12 groups / 16 venues), schedule generation
(104 unique matches) and standings computation.

## 🕒 Schedule & time zone

- Uses the **real FIFA World Cup 2026 schedule** — all 104 fixtures with their
  actual dates, venues and kick-off times, and the real group draw from the
  Final Draw (5 December 2025). Source data was compiled from Wikipedia's per-group
  and knockout schedule pages (see `lib/data/sources/schedule_data.dart`).
- Each fixture's venue-local kick-off is converted to an absolute **UTC** instant
  using the venue's summer UTC offset (Pacific −7, Central −5, Eastern −4,
  Mexico −6), then displayed in **Bangladesh Standard Time (UTC+6)**. Match detail
  also shows the stadium's local time.
- Match **results are simulated** (deterministically, from team ratings) only for
  fixtures already kicked off relative to the device clock, so the app feels live.

## 📝 Notes

- Flag rendering uses colour-coded country-code badges for consistent, premium
  cross-platform visuals (no dependency on flag-emoji font support).
- To re-target another time zone, change the `_bdtOffset` in
  `lib/data/models/match.dart` and the `+6` offsets in `FixturesProvider`.
