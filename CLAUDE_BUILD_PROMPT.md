# Full Build Prompt — Smart Campus Assistant (paste directly into Claude)

> Copy everything inside the code block below into Claude. It is self-contained: it defines the app,
> the complete design system, and all 12 screens, then tells Claude exactly what to output.

```
You are an expert Flutter UI engineer and product designer. Build the complete front-end for an
existing, already-designed mobile app called "Smart Campus Assistant". The design is FINAL — your
job is to reproduce it faithfully in clean Flutter code, NOT to redesign it. Follow the design
system as hard constraints. Do not invent new colors, fonts, radii, or shadows.

════════════════════════════════════════════════════════════════════════
APP
════════════════════════════════════════════════════════════════════════
Smart Campus Assistant — "Your University Life, Simplified."
A university companion app for managing academic life: schedules, courses, events, campus
navigation, announcements, plus an AI assistant. It is MULTI-ROLE:
  • Student        → Student Dashboard (schedule, courses, events, map, AI, announcements)
  • Professor/Staff → Staff Dashboard (own courses, urgent actions, announcements)
  • Administrator  → Admin Dashboard (system stats, users, campus-wide announcements)

Platform: Flutter, Material 3 base (customized), mobile portrait, 390×844 reference frame.
Aesthetic: Corporate-modern, tonal-layered, calm. Deep University Navy on soft off-white,
generous whitespace, 16px rounded corners, soft ambient shadows. A helpful companion, not a
bureaucratic tool.

Backend: Firebase (Auth, Firestore, Cloud Messaging, Storage). State via providers + stream
providers with local caching/persistent storage for offline-first reads. Device features: GPS
(campus map/navigation) and camera (QR login, profile photo, event check-in).

════════════════════════════════════════════════════════════════════════
FEATURES (functional spec — build the behavior, not just the visuals)
════════════════════════════════════════════════════════════════════════
F0. ACCOUNTS, AUTH & ROLES (multi-user)
  • Sign in with university ID + password (Firebase Auth). Alternatives: "Log in with University
    ID" (SSO), QR sign-in (camera scans a one-time code), and biometric unlock (Face/Touch ID).
  • "Remember me for 30 days" persists the session; otherwise session expires.
  • "Forgot Password?" → email reset flow.
  • Three roles with distinct home + permissions: Student (read-only consumer), Professor/Staff
    (manages own courses + posts announcements), Administrator (system-wide management). Role is
    stored on the user profile and gates every screen, action, and nav layout.
  • Role Selection lets a multi-role account choose context; single-role accounts route directly.

F1. DASHBOARD / HOME (role-aware landing)
  • Student: "Up Next" class (live countdown + one-tap Navigate to room), Daily Insight (AI tip),
    upcoming Deadlines, quick tiles (Events, Study Spaces).
  • Staff: Urgent Actions (e.g. room-change approvals), My Courses summary, Recent Announcements.
  • Admin: live system stats (Total Users, Active Students with trend, Published Announcements,
    Notification Engagement chart with Week/Month range toggle).
  • All dashboards stream live data and update in real time; pull-to-refresh; cached for offline.

F2. SCHEDULE & TIMETABLE (Student)
  • Day timeline of classes with status (Confirmed / Cancelled / Room Changed), time, room,
    professor. Tap a class → Course Details. "Next Assignment" reminder pinned. Date navigation
    (today / pick a day). Reflects live edits made by staff/admin (e.g. cancellations).

F3. COURSES (Student view / Staff manage)
  • Course Details: code, title, professor, weekly session pattern (MON/WED/FRI), upcoming
    deadlines (exams/assignments with due dates), downloadable resources (PDFs from Storage),
    and a per-course AI "Course Assistant".
  • Staff can create/edit their courses, sessions, deadlines, and upload resources.
  • "My Courses" list with enrolled/teaching count.

F4. EVENTS (discover + RSVP)
  • Browse campus events filtered by category (All / Academic / Career / Sports / Social).
    Featured events highlighted. Each event: cover image, title, date/time, location.
  • Actions: Join Event / Save Spot (RSVP, stored per user), Details, Share. Optional camera-based
    check-in at the event (QR). Joining schedules a reminder push notification.

F5. CAMPUS MAP & NAVIGATION (GPS device feature)
  • Live map with the user's GPS location and building/room pins. Search "Find a building or room".
    Filter chips (Cafe / Printers / Study Rooms). Tap a pin → bottom sheet with building info
    (open/closed status, facilities) → "Start Navigation" turn-by-turn to the destination.
  • Used by "Navigate" actions elsewhere (e.g. Up Next class → route to room).

F6. AI ASSISTANT (the AI component — out-of-scope feature)
  • Conversational campus assistant (LLM via API): answers "Where is my next class?", "What do I
    have today?", "Summarize announcements". Has context on the user's schedule, courses, events,
    and announcements. Can return rich answers (e.g. a map/room card with a "Go" deep-link).
  • Quick-suggestion chips. Per-course "Course Assistant" entry point. Streams responses; messages
    cached locally for history.

F7. ANNOUNCEMENTS & NOTIFICATIONS (push)
  • Feed of campus/department announcements: Urgent & Pinned section (emergency alerts) + Recent
    Updates grouped by department, each with an AI-generated summary. Search + filter.
  • Firebase Cloud Messaging push notifications for new/urgent announcements, event reminders, and
    schedule changes; deep-link into the relevant screen. Staff/Admin can publish announcements
    (compose, target audience/department, mark urgent/pinned) — gated by role.

F8. PROFILE & SETTINGS
  • View/edit profile (name, ID, photo via camera/gallery), notification preferences, biometric
    toggle, theme, sign out. Persisted to Firestore + cached locally.

F9. OFFLINE ACCESS (cached data — offline-first)
  • The app is fully usable without connectivity for everything previously loaded. On every screen,
    data is read CACHE-FIRST: render cached content instantly, then reconcile with the live stream
    when online. Never block the UI on the network.
  • Persist to local storage (e.g. Hive / Firestore offline persistence / shared_preferences for
    small prefs): the signed-in session + role, dashboards, schedule/timetable, course details and
    downloaded resource files, events + the user's RSVPs, announcements feed + AI summaries, AI chat
    history, and the last known map/building data. Cached resource PDFs open offline.
  • Connectivity awareness: detect online/offline; show a slim, on-brand "You're offline — showing
    saved data" banner (dismissible, non-blocking) and a per-item "last updated <time>" where useful.
  • Offline writes are QUEUED and replayed on reconnect (e.g. RSVP to an event, edit profile, staff
    posting an announcement): apply optimistically, mark as "Pending sync", and flush the outbound
    queue automatically when the connection returns; surface conflicts on-brand if a write fails.
  • Actions that strictly require live data (turn-by-turn GPS navigation, fresh AI responses, QR
    sign-in) degrade gracefully: disable with a clear "Requires connection" hint rather than erroring.
  • Cache is scoped per user and cleared on sign-out; respect a sensible size/TTL policy so stale
    data is refreshed when back online.

OUT-OF-COURSE-SCOPE FEATURES (≥3, per project requirements):
  (1) AI campus assistant + AI announcement summaries (LLM API).
  (2) GPS live map with turn-by-turn campus navigation.
  (3) Camera-based QR sign-in / event check-in + biometric authentication.
  (4) Push notifications with deep-linking.
  (5) Offline-first caching / persistent storage with stream providers (full offline access — see F9).

CROSS-CUTTING (every feature):
  • Error handling: connection-loss and wrong-input states show on-brand messages, retry affordances,
    and inline #BA1A1A validation — never raw exceptions.
  • Offline-first (F9): every read is cache-first then live; the app works fully offline on previously
    loaded data; writes queue and replay on reconnect; an "offline" banner appears when disconnected.
  • Role enforcement on both UI and (assume) security rules.

════════════════════════════════════════════════════════════════════════
DESIGN SYSTEM (hard constraints — centralize these as theme tokens)
════════════════════════════════════════════════════════════════════════
COLORS:
  primaryNavy        #002147   (primary buttons, active nav, hero cards)
  primaryDarkest     #000A1E   (darkest text/icons)
  onPrimary          #FFFFFF
  inversePrimary     #AEC7F6
  background         #F9F9F9   (app floor)
  card               #FFFFFF   (elevated surfaces ONLY)
  fill               #EEEEEE   (inputs, chips, tiles)
  fillLow            #F3F3F3
  secondaryCyan      #D0E7EA   (academic accents, AI bubbles, secondary buttons; text = navy)
  tertiaryPurple     #F3E5F5   (social/wellness/admin accent, insight cards)
  textPrimary        #1A1C1C
  textMuted          #44474E
  hint               #74777F
  border             #C4C6CF
  success            green     ("Confirmed", ▲ positive deltas)
  error              #BA1A1A   (urgent fill, inline validation errors)
  errorContainer     #FFDAD6   (urgent card bg)
  onErrorContainer   #93000A

TYPOGRAPHY (dual font — load both):
  Headings → "Hanken Grotesk":
    headlineLg 32 / w700 / -0.02em   (page greeting/title ONLY)
    headlineMd 24 / w600 / -0.01em
    headlineSm 20 / w600
  Body & UI → "Inter":
    bodyLg 16 / w400
    bodyMd 14 / w400
    labelLg 14 / w600 / 0.01em        (button text)
    labelSm 12 / w500                 (tags, helper text)

SPACING (8px grid): xs4 · sm12 · md16 · lg24 · xl32. Screen side margin = 20. Card padding = 16.
RADIUS: default 16 for cards/inputs/primary buttons. Tags/badges 4–8. Bottom sheets/modals = 24
        TOP corners only. Avatars/pills = full.
ELEVATION (shadows, not borders):
  Level 1 cards     → shadow offset(0,4) blur 12 navy @ opacity 0.05
  Level 2 floating  → shadow offset(0,8) blur 20 navy @ opacity 0.08  (bottom nav, FAB, active)

COMPONENTS (reuse exactly):
  • Primary button: navy fill, white labelLg, 16 radius, full-width in forms, ~52px tall.
  • Secondary button: cyan fill, navy text.
  • Outline button: 1px navy border, transparent fill.
  • Card: white, 16 radius, Level-1 shadow, OPTIONAL 4px colored LEFT accent bar denoting category:
      green = upcoming/confirmed · red = urgent · cyan = academic · purple = social · navy = neutral.
  • Input: #EEEEEE fill, 16 radius, leading icon, NO border until focus → 2px navy border.
            Inline error text in #BA1A1A.
  • Chip/tag: pill, labelSm. Filter-chip rows have ONE active (navy fill) + rest (fill #EEEEEE).
      Status chips: Confirmed (green tint) · OPEN NOW (cyan) · Urgent (red) · Featured (navy).
  • Bottom navigation: 5 items, blurred-white (glassmorphism), active = navy icon + small dot below.
      Student/Staff tabs: Home · Schedule · Map · Events · AI.
      (Staff variant: Home · Schedule · Events · Map · Profile, plus a navy "+" FAB.)
  • App bar: leading circular avatar OR back arrow, title "Campus Assistant"/page name, trailing bell.
  • AI chat bubbles: AI = cyan, left-aligned, 16 radius w/ bottom-LEFT corner 4.
      User = navy, white text, right-aligned, 16 radius w/ bottom-RIGHT corner 4.
      Rich bubbles can embed an image card + a "Go" action chip.
  • List row: title (bodyLg/labelLg) + meta (bodyMd muted) + trailing chevron → detail.
  • Stat card: big number (headlineLg) + label + tiny trend (▲4% in green).

LAYOUT RECIPE (every content screen): app bar → page title (headlineLg) + optional muted subtitle →
sections (header labelLg/headlineSm + optional "See All"/"View All" trailing action → cards/list) →
persistent bottom nav (except auth/splash/detail-with-back). Urgent/featured floats to TOP.
Margins 20 side · 16 between cards · 24 between sections.

BEHAVIOR: every screen handles loading / empty / error states on-brand (never raw exceptions);
inputs are validated with inline #BA1A1A error text; content & actions are gated by the active role.

════════════════════════════════════════════════════════════════════════
SCREENS TO BUILD (12) — reproduce each layout
════════════════════════════════════════════════════════════════════════
AUTH & ONBOARDING
1. Splash — off-white bg; centered navy rounded-square logo (sparkle glyph); app name (headlineLg);
   tagline "Your University Life, Simplified."; bottom: progress bar + "SECURE UNIVERSITY PORTAL"
   with shield icon.
2. Login — logo + "Campus Assistant" headline + subtitle. White card with: "Student or Staff ID"
   input (person icon, placeholder "e.g. 202400123"); "Password" input (lock icon) + "Forgot
   Password?" link; "Remember me for 30 days" checkbox; full-width navy LOGIN button; "OR" divider;
   cyan "Log in with University ID"; two outline buttons side-by-side: "Scan QR" | "Biometric";
   footer "Need technical assistance? Contact Support" + Privacy/Terms links.
3. Role Selection — app bar. "Choose Your Role" headline + subtitle. Three cards, each with a
   colored left accent (cyan / secondary / purple), circular tinted icon, role name, description,
   and a navy button: "Continue as Student" / "Continue as Faculty" / "Continue as Admin". Footer help.

STUDENT
4. Student Dashboard — "Welcome back, Alex" + avatar + bell. UP NEXT card (green left accent):
   "Class Starting Soon" cyan chip, "Advanced Calculus", time, room, navy "Navigate" button.
   "Daily Insight" card (purple tint, lightbulb icon). "Deadlines" section + "See All" → chevron
   list rows (e.g. Physics Lab Report — Due Tomorrow). Two square tiles: "Campus Events / Tech Mixer
   @ 5PM" (cyan) + "Study Spaces / Find a spot" (gray). Bottom nav.
5. Today's Schedule — "Today's Schedule" + date "Monday, October 23rd". Vertical TIMELINE (left
   dots + connecting line + time labels 09:00, 11:30, 14:00) of class cards: title + "Confirmed"
   green chip + time/room/professor rows (icons) + "View Course Details" button on the active one.
   Navy "NEXT ASSIGNMENT" banner pinned near bottom. Bottom nav (Schedule active).
6. Course Details — back-arrow app bar (course code "MATH-401"). Navy HERO card: code chip, course
   title "Advanced Calculus", professor avatar + "Dr. Emily Roberts" + department, "View Calendar"
   link. "Weekly Sessions" with MON/WED/FRI day badges + session rows. "Upcoming Deadlines"
   (Midterm Exam — date in red). "Course Resources" file list (Syllabus.pdf, Lecture Notes.pdf with
   size + download icon) + "View All Files" outline button. "Course Assistant" card → navy "Start
   Learning". Bottom nav.

DISCOVERY & NAVIGATION
7. Events — "Campus Events" headline + subtitle. Filter-chip row: All (active) · Academic · Career ·
   Sports. Event cards: cover image, "Featured" badge, title, date + location rows, navy "Join
   Event" / "Save Spot" + "Details"/share icons. Bottom nav (Events active).
8. Campus Map — avatar/bell bar. Search bar "Find a building or room" (mic icon). Filter chips
   (Cafe · Printers · Study Rooms) + layers icon. Map canvas with labeled location pins (e.g.
   "Science Center"). Bottom SHEET (top-24 radius): "Building B - Science Center", "OPEN NOW" cyan
   chip + share, "3 Labs, 10 Lecture Rooms, Cafe on Floor 1", three category buttons (LABS · ROOMS ·
   CAFE), navy "Start Navigation" button. Bottom nav (Map active).
9. AI Assistant — "CAMPUS AI" bar. "How can I help you today?" headline. Chat thread: cyan AI
   bubbles (left, with timestamp) + navy user bubbles (right); one rich AI bubble embeds a building
   image card "Room 202 - Art History" + a "Go" chip. Suggestion chips above input ("What do I have
   today?", "Summarize announcements"). Input bar "Ask anything about campus." with mic + navy send
   button. Bottom nav (AI active).
10. Announcements — search bar "Search announcements". "URGENT & PINNED": red card "Emergency Power
    Outage - Science Wing" with "Urgent" red badge, description, and an "AI Summary" tinted box.
    "Recent Updates" + Filter. Department-grouped cards (Engineering, General) with colored left
    accents, title, timestamp, and an "AI Summary" box each.

STAFF & ADMIN
11. Admin Dashboard — hamburger DRAWER + bell + avatar. "System Overview" headline + subtitle. Stat
    cards (navy left accent): "Total Users 12,402" · "Active Students 8,230 ▲4% increase" (green) ·
    "Published Announcements 124". "Notification Engagement" card with Week/Month toggle + a chart.
    Bottom nav.
12. Staff Dashboard — "Prof. Wilson" + avatar + bell. "Urgent Actions": red-accent warning card
    "Room Change Required" + chevron. "My Courses" + "View All" pill → course cards (left accent,
    schedule "Mon, Wed · 10:00 AM", "42 Students", subject icon). "Recent Announcements" list. Bottom
    nav (Home · Schedule · Events · Map · Profile) + navy "+" FAB.

════════════════════════════════════════════════════════════════════════
OUTPUT REQUIREMENTS
════════════════════════════════════════════════════════════════════════
• Use Flutter with a single shared theme: a ThemeData plus an AppColors / AppTextStyles / AppSpacing
  token file. Never hardcode a hex when a token exists.
• Build a library of reusable widgets first (PrimaryButton, SecondaryButton, OutlineButton,
  AppCard with optional accentColor, AppTextField, StatusChip, FilterChipBar, AppBottomNav,
  AppScaffold, ChatBubble, StatCard, SectionHeader, ListTileRow) — then compose screens from them.
• Use placeholder/mock data and stub navigation between screens (named routes). No backend needed
  yet, but structure so Firebase + providers can drop in later.
• Match spacing, radius, shadows, and the 4px category accent bars exactly. Keep it pixel-consistent
  across all screens.
• Wire fonts (Hanken Grotesk + Inter) via google_fonts or pubspec assets.
• Provide every screen with loading / empty / error variants where applicable.
• Organize into lib/theme, lib/widgets, lib/screens (one file per screen), lib/models,
  lib/services (auth, firestore, messaging, location, ai), lib/providers (one per feature in §FEATURES),
  and a lib/main.dart that sets up routing and starts at Splash → Login → Role Selection → role dashboard.
• Implement the FEATURES behaviorally with mock services behind interfaces, so real Firebase/LLM/GPS
  implementations drop in without touching the UI. Each feature gets a provider exposing loading/data/
  error states (use stream providers for live data) and reads cache-first.
• Offline-first (F9): add a lib/services local-cache layer (e.g. Hive box per feature) and a
  connectivity service; repositories return cached data immediately then emit live updates; an
  outbound write queue replays on reconnect; show the offline banner via a shared widget. Make the
  whole app demonstrably usable with the network off.

Deliver the complete code, file by file, with a short note on the folder structure and how to run it.
```
