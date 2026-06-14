#!/usr/bin/env python3
"""Generates the GoalVerse technical overview PDF."""
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak,
    Preformatted, HRFlowable,
)

OUT = r"F:\Personal_Passive_Income\Fifa 2026\GoalVerse-Technical-Overview.pdf"

NAVY = colors.HexColor("#0E2A4A")
BLUE = colors.HexColor("#2E9BE6")
LIGHT = colors.HexColor("#EAF2FB")
GREY = colors.HexColor("#5B6B7B")
DARK = colors.HexColor("#1A2230")

ss = getSampleStyleSheet()
H1 = ParagraphStyle("H1", parent=ss["Heading1"], textColor=NAVY, fontSize=16,
                    spaceBefore=14, spaceAfter=6, fontName="Helvetica-Bold")
H2 = ParagraphStyle("H2", parent=ss["Heading2"], textColor=BLUE, fontSize=12.5,
                    spaceBefore=10, spaceAfter=4, fontName="Helvetica-Bold")
BODY = ParagraphStyle("BODY", parent=ss["Normal"], fontSize=10, leading=15,
                      textColor=DARK, spaceAfter=6, alignment=TA_LEFT)
BULLET = ParagraphStyle("BULLET", parent=BODY, leftIndent=12, bulletIndent=2,
                        spaceAfter=3)
CODE = ParagraphStyle("CODE", parent=ss["Code"], fontSize=8.5, leading=11,
                      textColor=colors.HexColor("#0B2239"),
                      backColor=colors.HexColor("#F2F6FB"), borderPadding=6,
                      leftIndent=2, rightIndent=2)
SMALL = ParagraphStyle("SMALL", parent=BODY, fontSize=8.5, textColor=GREY)
CELL = ParagraphStyle("CELL", parent=BODY, fontSize=8.8, leading=12, spaceAfter=0)
CELLB = ParagraphStyle("CELLB", parent=CELL, fontName="Helvetica-Bold")
HCELL = ParagraphStyle("HCELL", parent=CELL, fontName="Helvetica-Bold",
                       textColor=colors.white)
TITLE = ParagraphStyle("TITLE", parent=ss["Title"], textColor=NAVY, fontSize=30,
                       leading=36, fontName="Helvetica-Bold", spaceAfter=14)
SUB = ParagraphStyle("SUB", parent=ss["Normal"], fontSize=12.5, textColor=BLUE,
                     alignment=TA_CENTER, spaceAfter=2)
SUB2 = ParagraphStyle("SUB2", parent=ss["Normal"], fontSize=10, textColor=GREY,
                      alignment=TA_CENTER)

story = []


def h1(t): story.append(Paragraph(t, H1))
def h2(t): story.append(Paragraph(t, H2))
def p(t): story.append(Paragraph(t, BODY))
def sp(h=6): story.append(Spacer(1, h))
def bullets(items):
    for it in items:
        story.append(Paragraph("&bull;&nbsp;&nbsp;" + it, BULLET))
    sp(4)
def code(t): story.append(Preformatted(t, CODE))
def rule(): story.append(HRFlowable(width="100%", thickness=0.6, color=colors.HexColor("#CBD7E6"), spaceBefore=4, spaceAfter=8))


def table(header, rows, widths):
    data = [[Paragraph(c, HCELL) for c in header]]
    for r in rows:
        data.append([Paragraph(c, CELL) for c in r])
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 8.8),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#CBD7E6")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    sp(8)


# ---------------- Cover ----------------
sp(120)
story.append(Paragraph("GoalVerse", TITLE))
story.append(Paragraph("FIFA World Cup 2026 - Companion &amp; Prediction Platform", SUB))
sp(6)
story.append(Paragraph("Technical Architecture &amp; Data-Flow Overview", SUB2))
sp(40)
story.append(HRFlowable(width="55%", thickness=1.2, color=BLUE))
sp(10)
story.append(Paragraph(
    "How the system is structured, where its data comes from, and how each "
    "part works together - from the schedule and live scores to the "
    "admin-driven prediction-scoring engine.", SUB2))
sp(150)
story.append(Paragraph("Repository: github.com/NasirSunny50/GoalVerse (private)", SMALL))
story.append(Paragraph("Stack: Flutter 3.41 / Dart 3.11 app &nbsp;|&nbsp; Dart (shelf) + SQLite backend &nbsp;|&nbsp; Docker", SMALL))
story.append(PageBreak())

# ---------------- 1. Overview ----------------
h1("1. System Overview")
p("GoalVerse is a premium Flutter companion app for the FIFA World Cup 2026 "
  "with a built-in <b>prediction competition</b> (\"Compete\"). It pairs a "
  "cross-platform mobile app with a lightweight Dart backend and a SQLite "
  "database. The system has three logical parts:")
bullets([
    "<b>The app (client)</b> - the full tournament experience: schedule, teams, "
    "venues, live scores, standings, and the Compete UI (predictions, "
    "leaderboard, admin panel).",
    "<b>The backend (server)</b> - owns all Compete logic: accounts, prediction "
    "storage, scoring, leaderboards and the admin result entry. A Dart "
    "<font face='Courier'>shelf</font> HTTP server on port 8787.",
    "<b>The database</b> - a single SQLite file holding users, sessions, "
    "predictions and admin-entered results.",
])
p("A core design principle: <b>the prediction competition never depends on "
  "third-party live data.</b> Scoring is driven exclusively by results an "
  "administrator enters, which makes points deterministic, auditable and "
  "immune to unreliable external feeds.")

h2("Technology stack")
table(["Layer", "Technology"], [
    ["Mobile app", "Flutter 3.41 / Dart 3.11, Material 3, provider state management"],
    ["App data/HTTP", "http package; bundled Inter &amp; SpaceGrotesk fonts"],
    ["Backend", "Dart (shelf / shelf_router), runs as a native executable"],
    ["Database", "SQLite (sqlite3 package), single-file storage"],
    ["Live scores (display only)", "TheSportsDB free API (league 4429)"],
    ["Deployment", "Docker (multi-stage), docker compose"],
], [38*mm, 120*mm])

# ---------------- 2. Architecture ----------------
h1("2. High-Level Architecture")
p("The app talks to two independent data sources, and they serve very "
  "different purposes:")
code(
"""                         +-------------------------------+
                         |        Flutter App            |
                         |  (Android / Web / Windows)    |
                         +---------------+---------------+
                                         |
            DISPLAY scores (read-only)   |   COMPETE (accounts, predictions)
       +---------------------------------+----------------------------+
       v                                                              v
+--------------------+                                  +---------------------------+
|   TheSportsDB API  |                                  |   GoalVerse Backend       |
|  (live/finished    |                                  |   Dart shelf  :8787       |
|   match scores)    |                                  |   +---------------------+ |
+--------------------+                                  |   |   SQLite database   | |
   used only to show                                   |   | users / sessions /  | |
   real scores on the                                  |   | predictions /       | |
   Home & Fixtures tabs                                |   | match_results       | |
                                                       |   +---------------------+ |
                                                       +-------------+-------------+
                                                                     ^
                                                                     | enters real results
                                                              +------+-------+
                                                              |    Admin     |
                                                              | (in-app panel)|
                                                              +--------------+""")
p("The left path (TheSportsDB) is <b>cosmetic</b> - it only paints real live "
  "scores onto the schedule screens. The right path (the backend) is the "
  "<b>system of record</b> for the competition. The two never mix: a "
  "prediction is graded only against what the admin records.")

# ---------------- 3. Data sources ----------------
h1("3. Where the Data Comes From")
p("Three distinct data sources feed the system, each with a clear role:")
table(["Source", "What it provides", "Used for"], [
    ["Static schedule (in-app)",
     "The real 104-fixture WC 2026 schedule - groups, teams, venues, kick-off "
     "dates/times (<font face='Courier'>schedule_data.dart</font>).",
     "The single source of truth for the fixture list, everywhere."],
    ["TheSportsDB (external API)",
     "Real live / finished match scores and status (league 4429, "
     "<font face='Courier'>eventsday.php</font>, no key).",
     "DISPLAY only - live scores on Home &amp; Fixtures. NOT used for scoring."],
    ["Admin-entered results",
     "The real outcome of each match: score, winner, first scorer, knockout "
     "penalties; plus knockout team assignments and the tournament outcome.",
     "The ONLY source used to score predictions. Stored server-side."],
], [33*mm, 78*mm, 47*mm])
p("Note: an earlier build simulated results deterministically from team "
  "ratings; that was fully removed. The app now shows <b>only real data</b>, "
  "and scoring uses <b>only admin data</b>.")

story.append(PageBreak())

# ---------------- 4. Data flow ----------------
h1("4. End-to-End Data Flow")

h2("4.1  Building the schedule")
p("On launch the app constructs the 104 matches from the static schedule. "
  "Each kick-off is stored as an absolute <b>UTC</b> instant (converted from "
  "the stadium's local time). For display it is shown in <b>Bangladesh time "
  "(UTC+6)</b>; status and countdowns are computed from UTC vs the live clock.")

h2("4.2  Live scores (display)")
p("A provider polls TheSportsDB every 30 seconds, matches events to fixtures "
  "by a canonical team-name key, and overlays the real score/status onto each "
  "match. If a match has no real data yet, it simply shows as scheduled - no "
  "invented numbers. Group standings are computed from these real results.")

h2("4.3  Compete: registration &amp; login")
bullets([
    "Register with name, employee ID, email and password -> the server sends an "
    "OTP (demo code <font face='Courier'>123456</font>) -> verifying the OTP "
    "creates the account and returns a bearer token.",
    "Passwords are stored as <b>salted SHA-256</b> hashes (never plaintext).",
    "The token maps to a session row; every authenticated request carries "
    "<font face='Courier'>Authorization: Bearer &lt;token&gt;</font>.",
])

h2("4.4  Making a prediction")
p("For any upcoming match a user fills in independent <b>markets</b> (below) "
  "and saves. The app sends the prediction to the backend, which stores it "
  "against the user + match. Predictions <b>lock at kick-off</b>: after that "
  "the server rejects edits with HTTP 409, so a locked pick can never change.")

h2("4.5  Admin enters the result")
p("After a match, the administrator signs in (on the same login screen, with "
  "hardcoded admin credentials) and is routed to an in-app <b>Admin Panel</b>. "
  "For each match the admin records the real outcome - final score, winner, "
  "first team to score, and (knockouts) whether it went to penalties. "
  "Over/Under and Both-Teams-To-Score are derived automatically from the "
  "score at the moment of entry and stored alongside it.")

h2("4.6  Scoring &amp; leaderboard")
p("Scoring is computed on demand. When the app requests stats / leaderboard / "
  "the prediction review, the server compares each stored prediction to the "
  "admin result for that match, awards points per market, and aggregates "
  "totals, rank, accuracy and streak. There is no background job and no live "
  "feed in this path - points are a pure function of (prediction, admin "
  "result).")

h2("4.7  Read-only review")
p("Once a match is scored, users open it read-only and see, per market, "
  "whether they were right or wrong and the points earned, plus the actual "
  "answer. Correctness is computed by the <b>server</b> (same logic as "
  "scoring) and sent to the app, so the ticks always agree with the points.")

# ---------------- 5. Scoring engine ----------------
h1("5. The Scoring Engine")
p("Every market is <b>independent and additive</b> - each correct answer adds "
  "its own points (so getting the exact score also earns the match-winner "
  "points). A perfect group-stage prediction is 10+25+12+8+8 = <b>63</b> "
  "points (knockout adds up to +10).")
table(["Market", "Points", "Correct when...", "Result source"], [
    ["Match Winner", "10", "Predicted side (home/draw/away) matches.", "Admin (or derived from score)"],
    ["Exact Score", "25", "Both predicted scores match exactly.", "Admin score"],
    ["First Team to Score", "12", "Predicted side (home/away/none) matches.", "Admin"],
    ["Total Goals", "8", "Under 3 (0-2) vs 3 or more matches.", "Derived from admin score"],
    ["Both Teams to Score", "8", "Yes/No matches.", "Derived from admin score"],
    ["Penalties (knockout)", "10", "Yes/No - did it go to a shootout.", "Admin"],
], [38*mm, 14*mm, 64*mm, 42*mm])
p("<b>Tournament-long markets</b> (graded once the Final is recorded): "
  "Champion +50, Runner-up +30, Golden Boot +20, Golden Glove +20 (each "
  "predicted as a team). These are double-gated - they only pay out when the "
  "admin has recorded the outcome <i>and</i> the Final has kicked off.")

story.append(PageBreak())

# ---------------- 6. Backend ----------------
h1("6. The Backend &amp; Database")
h2("6.1  Database schema (SQLite)")
table(["Table", "Holds"], [
    ["users", "email, name, employee_id, salted SHA-256 pw_hash, salt, created_at"],
    ["sessions", "bearer token -> email (login sessions)"],
    ["match_predictions", "email, match_id, winner, home/away score, first_scorer, over_under, btts, penalties"],
    ["match_results", "match_id, admin-assigned home/away team, winner, score, first_scorer, over_under, btts, penalties, confirmed_at"],
    ["tournament_predictions", "email, winner / runner-up / golden-boot / golden-glove team"],
], [44*mm, 114*mm])
p("The schedule itself is not in the DB; it is exported from the app's own "
  "engine to <font face='Courier'>data/fixtures.json</font> so match IDs match "
  "exactly on both sides.")

h2("6.2  Key HTTP endpoints")
table(["Method &amp; Path", "Auth", "Purpose"], [
    ["GET /health", "-", "Liveness check"],
    ["POST /auth/register, /auth/verify-otp, /auth/login", "-", "Account creation &amp; sign-in (admin signs in here too)"],
    ["GET /me, /stats", "Bearer", "Profile + computed stats"],
    ["GET /predictions", "Bearer", "User's predictions + per-match review (result, points, hits)"],
    ["PUT /predictions/match/&lt;id&gt;", "Bearer", "Save a match prediction (locks at kick-off)"],
    ["PUT /predictions/tournament", "Bearer", "Save tournament picks"],
    ["GET /leaderboard?period=...", "optional", "Ranked board (global / weekly / monthly / all-time)"],
    ["GET /fixtures", "-", "Schedule + admin knockout teams + results overlay"],
    ["GET /admin/results", "Admin", "Every fixture with its admin result"],
    ["PUT /admin/result/&lt;id&gt;", "Admin", "Record a match result / assign knockout teams"],
    ["DELETE /admin/result/&lt;id&gt;", "Admin", "Clear a match result"],
], [62*mm, 18*mm, 78*mm])

# ---------------- 7. Admin & knockout ----------------
h1("7. Admin System &amp; Knockout Handling")
bullets([
    "<b>Admin identity</b> is a hardcoded account, enforced server-side: a "
    "request is admin only if its token belongs to the admin email. The admin "
    "email cannot be registered or used to predict, and all "
    "<font face='Courier'>/admin/*</font> endpoints reject non-admins with 403.",
    "<b>Knockout teams:</b> the schedule's 32 knockout matches start as "
    "placeholders (\"Winner Group A\"). When the bracket is known the admin "
    "assigns the two real teams; the assignment is overlaid through "
    "<font face='Courier'>/fixtures</font> so the match shows real teams and "
    "becomes predictable everywhere.",
    "Predictions are <b>side-based</b> (home/away), so grading a knockout match "
    "is identical to a group match once its teams are set.",
])

# ---------------- 8. Security ----------------
h1("8. Security &amp; Integrity")
bullets([
    "Passwords: salted SHA-256, never stored or transmitted in plaintext.",
    "Locked predictions are immutable - the server rejects any edit after "
    "kick-off (HTTP 409), independent of the client.",
    "Admin authority is verified on the server for every admin action; the "
    "client is never trusted to declare itself admin.",
    "Per-market correctness and points come only from the server, so the "
    "displayed ticks can never disagree with the awarded points.",
    "For production, the hardcoded admin password should be overridden via the "
    "<font face='Courier'>GV_ADMIN_PASSWORD</font> environment variable, and "
    "the repository kept private.",
])

# ---------------- 9. Deployment ----------------
h1("9. Deployment (Docker)")
p("The backend ships as a Docker image so it can run on any host. A "
  "multi-stage build compiles the Dart server to a native executable and runs "
  "it on a slim Debian image with the system SQLite library.")
code(
"""# from the repo root
docker compose up -d --build     # backend on port 8787, with DB + fixtures

# build the release app pointed at that backend
scripts/build-apk.sh http://<server-ip>:8787
adb install -r build/app/outputs/flutter-apk/app-release.apk""")
p("On first run the container auto-creates the SQLite database and seeds the "
  "schedule into a persistent volume (<font face='Courier'>goalverse-data</font>). "
  "The database survives container and image rebuilds; it starts empty (no "
  "accounts) with the admin built in.")

# ---------------- 10. Backup & DR ----------------
h1("10. Backup &amp; Disaster Recovery")
p("All competition state lives in the SQLite database inside the Docker "
  "volume. Backups protect against an accidental volume wipe, corruption or a "
  "dead host.")
table(["Scenario", "Recovery action"], [
    ["Container / image broke", "docker compose up -d --build (volume data intact)"],
    ["Volume wiped (down -v)", "docker compose up -d, then restore the latest backup"],
    ["Database corruption", "PRAGMA integrity_check; if not ok, restore last good backup"],
    ["Host machine died", "On a new host: clone, compose up, restore an off-host backup"],
], [42*mm, 116*mm])
code(
"""scripts/db-backup.sh                          # consistent online snapshot -> backups/
scripts/db-restore.sh backups/goalverse-<ts>.db   # restore into the running stack""")
p("Best practice: take a backup before each round of matches, and copy it "
  "off-machine (cloud / another disk). This full cycle - backup, simulated "
  "data loss, restore - has been verified end-to-end.", )

sp(10)
rule()
story.append(Paragraph(
    "GoalVerse Technical Overview &nbsp;|&nbsp; FIFA World Cup 2026 prediction "
    "platform &nbsp;|&nbsp; Flutter + Dart + SQLite + Docker", SMALL))


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY)
    canvas.drawString(20*mm, 12*mm, "GoalVerse - Technical Overview")
    canvas.drawRightString(190*mm, 12*mm, "Page %d" % doc.page)
    canvas.setStrokeColor(colors.HexColor("#CBD7E6"))
    canvas.line(20*mm, 15*mm, 190*mm, 15*mm)
    canvas.restoreState()


doc = SimpleDocTemplate(OUT, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm,
                        leftMargin=20*mm, rightMargin=20*mm,
                        title="GoalVerse - Technical Overview",
                        author="GoalVerse")
doc.build(story, onLaterPages=footer, onFirstPage=lambda c, d: None)
print("WROTE", OUT)
