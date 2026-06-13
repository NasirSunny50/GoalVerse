# GoalVerse — Deploy & Build Guide

Two parts: the **backend** (Docker — runs anywhere) and the **app** (release
APK, built to point at the backend). Run them in this order.

---

## 1) Backend — Docker (with DB, fixtures, everything)

Needs Docker. From the repo root:

```bash
docker compose up -d --build
```

This builds the image and starts the backend on **port 8787**. On the first run
it **automatically**:

- creates the SQLite database `goalverse.db` with all tables,
- seeds the 104-match schedule (`fixtures.json`),
- keeps everything in the persistent **`goalverse-data`** volume (survives
  restarts and `docker compose down`).

The DB starts **empty** (no accounts — users register in the app). The admin is
built in: **`admin@gmail.com` / `Admin@123`** (override with the
`GV_ADMIN_PASSWORD` env var in `docker-compose.yml` for production).

Handy commands:

```bash
curl http://localhost:8787/health     # -> {"ok":true}
docker compose logs -f                 # watch logs
docker compose down                    # stop  (DATA KEPT)
docker compose down -v                 # stop + WIPE all data
```

Convenience wrappers: `scripts/backend-up.sh` (Linux/macOS) or
`scripts\backend-up.bat` (Windows).

---

## 2) App — release APK (pointed at the backend)

The app needs to know the backend URL via `API_BASE`. Pick the case that
matches where the backend runs.

### Case A — backend on the SAME PC as the phone (USB)

```bash
adb reverse tcp:8787 tcp:8787                 # phone's localhost -> this PC
scripts/build-apk.sh                          # defaults to http://localhost:8787
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Windows: `scripts\build-apk.bat`

### Case B — backend on another host / cloud (over the network)

```bash
scripts/build-apk.sh http://<SERVER-IP>:8787
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Windows: `scripts\build-apk.bat http://<SERVER-IP>:8787`

Both work because the app ships with cleartext HTTP enabled. The APK is always
written to `build/app/outputs/flutter-apk/app-release.apk`.

---

## 3) Day-to-day

| Task | Command |
|---|---|
| Start backend | `docker compose up -d` |
| Stop backend (keep data) | `docker compose down` |
| Rebuild app after code changes | re-run `scripts/build-apk.*`, then `adb install -r ...` |
| Admin enters results | log in as the admin in the app → Admin panel |
| Inspect DB | `docker compose exec goalverse-backend /app/bin/server` is the server; for tables run the tools from `server/` locally, or use a SQLite viewer on the volume |
