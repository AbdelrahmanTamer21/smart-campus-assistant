# Smart Campus Assistant — UI Master Prompt & Design System

> **Purpose of this document.** The app's screens were already designed and presented in Stitch
> ([project link](https://stitch.withgoogle.com/projects/3225564839112857280)). This file is the
> single source of truth for building **any new feature** so that it looks like it belongs in the
> same app. Paste the [Master Prompt](#1-master-prompt-copy-paste) into Claude (or any code/design
> assistant), fill the `<<...>>` slots, and it will generate UI that does **not deviate** from what
> was presented.

---

## 0. App Context (always include)

**App:** Smart Campus Assistant — *"Your University Life, Simplified."*
A mobile companion for a university that helps students, faculty, and admins manage academic life
(schedules, courses, events, campus navigation, announcements) with an AI assistant.

**Platform:** Flutter (mobile, portrait, 390×844 reference frame). Material 3 base, customized.

**User roles (multi-user app):**
| Role | Home screen | Primary jobs |
|------|-------------|--------------|
| **Student** | Student Dashboard | schedule, courses, events, map, AI chat, announcements |
| **Professor / Staff** | Staff Dashboard | manage own courses, urgent actions, post announcements |
| **Administrator** | Admin Dashboard | system stats, manage users, publish campus-wide announcements |

**Visual identity in one line:** *Corporate-modern, tonal-layered, calm. Deep University Navy on
soft off-white, generous whitespace, 16px rounded corners everywhere, soft ambient shadows — a
helpful companion, never a bureaucratic tool.*

---

## 1. Master Prompt (copy-paste)

```
You are building a new screen/feature for "Smart Campus Assistant", an existing Flutter
mobile app for university life. The visual design is ALREADY ESTABLISHED and must NOT be
redesigned — match it exactly. Treat the Design System below as hard constraints.

# FEATURE TO BUILD
<<Describe the feature in 1–3 sentences. Who uses it (Student/Staff/Admin), what it does,
what data it shows, what actions exist.>>

# NON-NEGOTIABLE DESIGN SYSTEM
Style: Corporate-modern, tonal layering, calm cognitive load. Mobile-first, portrait.

COLORS (use these tokens, never invent new hues):
- Primary / brand / primary buttons / active nav .. Deep Navy  #002147 (text on it: #FFFFFF)
- Darkest primary (headlines on light) ............ #000A1E
- Background (app floor) .......................... #F9F9F9
- Card / elevated surface ......................... #FFFFFF
- Subtle fill (inputs, chips, tiles) .............. #EEEEEE  (lower: #F3F3F3)
- Secondary (academic / cyan accents, AI bubbles) . #D0E7EA fill, text #002147
- Tertiary (social / wellness / admin accent) ..... #F3E5F5 (soft purple) fill
- Text primary .................................... #1A1C1C
- Text secondary / muted .......................... #44474E  (hint: #74777F)
- Outline / borders ............................... #C4C6CF
- Success (confirmed, positive deltas) ............ green #2E7D5B-ish (use for chips/▲)
- Error / urgent .................................. #BA1A1A fill, container #FFDAD6, text #93000A

TYPOGRAPHY (dual font):
- Headings → "Hanken Grotesk": headline-lg 32/700, headline-md 24/600, headline-sm 20/600
- Body/UI  → "Inter": body-lg 16/400, body-md 14/400, label-lg 14/600 (buttons), label-sm 12/500 (tags)
- Strict hierarchy: headline-lg ONLY for page greeting/title. label-lg for buttons. label-sm for tags.

SPACING: 8px grid. xs4 · sm12 · md16 · lg24 · xl32. Screen side margin = 20px. Card padding = 16px.

RADIUS: default 16px (1rem) for cards/inputs/primary buttons. Tags/badges 4–8px.
Bottom sheets & modals: top corners only, 24px. Pills/avatars: full (9999px).

ELEVATION (shadows, not borders):
- Cards (Level 1): white, shadow Y4 blur12 opacity .05 navy-tinted.
- Floating / bottom-nav / active (Level 2): shadow Y8 blur20 opacity .08.

COMPONENTS (reuse these exact specs):
- Primary button: navy fill, white label-lg, 16px radius, full-width in forms, ~52px tall.
- Secondary button: cyan (#D0E7EA) fill, navy text.
- Outline button: 1px navy border, transparent fill (e.g. "Details", "View All Files").
- Card: white, 16px radius, Level-1 shadow, OPTIONAL 4px colored LEFT accent bar denoting
  category (green=upcoming/confirmed, navy=neutral, red=urgent, cyan=academic, purple=social).
- Input: #EEEEEE fill, 16px radius, leading icon, no border until focus → 2px navy border.
- Chip/tag: pill, label-sm. Filter chips row with one active (navy fill) + rest (subtle fill).
  Status chips: "Confirmed" (green tint), "OPEN NOW" (cyan), "Urgent" (red), "Featured" (navy).
- Bottom navigation: 5 items, blurred-white (glassmorphism), active = navy icon + small dot below.
  Student/Staff order: Home · Schedule · Map · Events · AI  (Staff swaps to ...Events · Map · Profile + a "+" FAB).
- App bar: leading circular avatar OR back arrow, centered/left "Campus Assistant", trailing bell.
- AI chat bubbles: AI = cyan, left-aligned, 16px radius w/ bottom-LEFT corner 4px.
  User = navy, white text, right-aligned, 16px radius w/ bottom-RIGHT corner 4px.
  Rich bubbles may embed an image card + a "Go" action chip.
- List row: title (body-lg/label-lg) + meta (body-md muted) + trailing chevron. Tap → detail.
- Stat card (dashboards): big number (headline-lg) + label + tiny trend (▲4% green).

# LAYOUT RECIPE (every content screen)
1. App bar (avatar/back + title + bell).
2. Page title: headline-lg (or -md), optional one-line muted subtitle.
3. Content in sections: a label-lg/headline-sm section header, optional "See All"/"View All"
   trailing action, then cards/list.
4. Urgent/featured content floats to TOP with a red or accent treatment.
5. Persistent bottom navigation (unless it's an auth/splash/detail-with-back screen).
Use 20px side margins, 16px gaps between cards, 24px between sections.

# BEHAVIOR / NON-UI (per project requirements)
- Handle loading, empty, and error states (connection issues, wrong input) with on-brand
  messages — never raw exceptions. Inputs are validated; show inline error text in #BA1A1A.
- Respect the user's role: only show actions/data permitted for <<role>>.

# OUTPUT
Produce Flutter widget code using the shared theme tokens/widgets named in the Design System
(do NOT hardcode hex if a token exists). Build reusable widgets, match spacing/radius/shadow
exactly, and keep it pixel-consistent with the existing screens. Briefly note any new shared
widget you introduce.

Do not introduce new colors, fonts, radii, or shadow styles. When in doubt, copy an existing
component from the screen catalog below.
```

---

## 2. Design System Reference (full tokens)

### 2.1 Color tokens
| Token | Hex | Use |
|-------|-----|-----|
| `primary` | `#000A1E` | darkest text/icons on light |
| `primary-container` / **brand navy** | `#002147` | buttons, active nav, hero cards |
| `on-primary` | `#FFFFFF` | text on navy |
| `inverse-primary` | `#AEC7F6` | navy-on-dark accents |
| `secondary-container` (cyan) | `#D0E7EA` | academic accents, AI bubbles, secondary btn |
| `tertiary-container` (purple) | `#F3E5F5` | social/wellness/admin accent, insight cards |
| `background` / `surface` | `#F9F9F9` | app floor |
| `surface-container-lowest` | `#FFFFFF` | cards |
| `surface-container` | `#EEEEEE` | input fill, chips, tiles |
| `surface-container-low` | `#F3F3F3` | subtle fill |
| `on-surface` | `#1A1C1C` | primary text |
| `on-surface-variant` | `#44474E` | secondary/muted text |
| `outline` | `#74777F` | hint text |
| `outline-variant` | `#C4C6CF` | borders/dividers |
| `error` | `#BA1A1A` | urgent fill, inline errors |
| `error-container` | `#FFDAD6` | urgent card bg |
| `on-error-container` | `#93000A` | urgent text |
| success (functional) | green | "Confirmed", positive deltas (▲) |

> Soft-purple `#F3E5F5` and cyan `#E0F7FA`/`#D0E7EA` were the explicit override secondary/tertiary
> colors. Neutral floor override is `#F5F5F5`. Pure white is reserved for cards only.

### 2.2 Typography
- **Hanken Grotesk** (headings): `headline-lg` 32/700/-0.02em, `headline-md` 24/600/-0.01em,
  `headline-sm` 20/600, `headline-lg-mobile` 28/700.
- **Inter** (UI/body): `body-lg` 16/400, `body-md` 14/400, `label-lg` 14/600/0.01em (buttons),
  `label-sm` 12/500 (tags, helper text).

### 2.3 Spacing · Radius · Elevation
- **Spacing (8px base):** xs 4 · sm 12 · md 16 · lg 24 · xl 32 · gutter 16 · mobile margin 20.
- **Radius:** sm 4 · default 8 · md 12 · lg 16 (**standard**) · xl 24 (sheets/modals, top-only) · full.
- **Elevation:** L1 cards = Y4 B12 op.05 navy; L2 floating/nav/active = Y8 B20 op.08. Depth via
  shadows + tonal tiers, **not** heavy outlines.

---

## 3. Screen Catalog (12 presented screens — copy these patterns)

> Use these as the visual reference for the kind of screen you're adding. Match the closest archetype.

### Auth & Onboarding
1. **Splash** — Centered navy rounded-square logo (sparkle glyph), app name (headline), tagline,
   bottom progress bar + "SECURE UNIVERSITY PORTAL" with shield icon. Off-white bg.
2. **Login** — Logo + "Campus Assistant" headline + subtitle. White card: "Student or Staff ID"
   input (person icon, e.g. 202400123), "Password" input (lock icon) + "Forgot Password?" link,
   "Remember me for 30 days" checkbox, full-width navy **Login**. "OR" divider → cyan **Log in with
   University ID** → two outline buttons: **Scan QR** | **Biometric**. Footer: Contact Support, Privacy/Terms.
3. **Role Selection** — App bar. "Choose Your Role" headline + subtitle. Three cards, each with a
   colored left accent (cyan/secondary/purple), a circular tinted icon, role name, description, and
   a navy **Continue as Student / Faculty / Admin** button. Footer help text.

### Student
4. **Student Dashboard** — "Welcome back, Alex" + avatar + bell. **UP NEXT** card (green left
   accent): "Class Starting Soon" cyan chip, class title, time, room, navy **Navigate** button.
   **Daily Insight** card (purple tint, lightbulb). **Deadlines** section + "See All" → chevron list
   rows. Two square tiles: "Campus Events" (cyan) + "Study Spaces" (gray). Bottom nav.
5. **Today's Schedule** — "Today's Schedule" + date. Vertical **timeline** (dots + line + time
   labels) of class cards: title + "Confirmed" green chip + time/room/professor rows + "View Course
   Details" button on active. Navy "NEXT ASSIGNMENT" banner pinned at bottom. Bottom nav.
6. **Course Details** — Back-arrow app bar. Navy **hero card**: course code chip (MATH-401), course
   title, professor avatar+name+dept, "View Calendar". **Weekly Sessions** (MON/WED/FRI day badges).
   **Upcoming Deadlines** (Midterm — red date). **Course Resources** file list (pdf rows + download)
   + "View All Files" outline. **Course Assistant** card → navy **Start Learning**. Bottom nav.

### Discovery & Navigation
7. **Events** — "Campus Events" + subtitle. Filter chips row (All active · Academic · Career ·
   Sports). Event cards: cover image, "Featured" badge, title, date/location rows, navy **Join
   Event** / **Save Spot** + Details/share. Bottom nav.
8. **Campus Map** — Avatar/bell bar. Search "Find a building or room" (mic). Filter chips (Cafe ·
   Printers · Study Rooms) + layers icon. Map canvas with labeled pins. **Bottom sheet** (top-24px
   radius): building name, "OPEN NOW" cyan chip + share, facility summary, three category buttons
   (LABS · ROOMS · CAFE), navy **Start Navigation**. Bottom nav (Map active).
9. **AI Assistant** — "CAMPUS AI" bar. "How can I help you today?" headline. Chat: cyan AI bubbles
   (left) + navy user bubbles (right) with timestamps; rich bubble embeds image card + "Go" chip.
   Suggestion chips above input. Input "Ask anything about campus." (mic + navy send). Bottom nav (AI active).
10. **Announcements** — Search bar. **URGENT & PINNED**: red card with "Urgent" badge + an "AI
    Summary" tinted box. **Recent Updates** + Filter: department-grouped cards (Engineering / General)
    with colored left accents, title, timestamp, "AI Summary" box.

### Staff & Admin
11. **Admin Dashboard** — Hamburger **drawer** + bell + avatar. "System Overview" + subtitle. Stat
    cards (navy left accent): Total Users 12,402 · Active Students 8,230 (▲4% green) · Published
    Announcements 124. "Notification Engagement" card with Week/Month toggle + chart. Bottom nav.
12. **Staff Dashboard** — "Prof. Wilson" + avatar. **Urgent Actions**: red-accent warning card +
    chevron. **My Courses** + "View All" pill → course cards (left accent, schedule, "42 Students",
    subject icon). **Recent Announcements** list. Bottom nav (Home·Schedule·Events·Map·Profile) + **+ FAB**.

---

## 4. Cross-cutting rules (do-not-deviate checklist)

- [ ] Background is `#F9F9F9`; only **cards** are pure white.
- [ ] Every card/input/primary-button uses **16px** radius. Sheets = 24px top only.
- [ ] Depth = soft navy-tinted shadow, **never** heavy borders.
- [ ] Headings in **Hanken Grotesk**, everything else **Inter**. No third font.
- [ ] One navy primary action per view; auxiliary actions are cyan (secondary) or outline.
- [ ] Category meaning is color-coded via a **4px left accent bar**: green=upcoming/confirmed,
      red=urgent, cyan=academic, purple=social/wellness, navy=neutral.
- [ ] 20px side margins · 16px between cards · 24px between sections · 8px grid throughout.
- [ ] Bottom nav present on top-level tabs; back-arrow app bar on detail screens.
- [ ] Urgent/featured content floats to the top with red/accent treatment.
- [ ] Status communicated with pill chips (Confirmed / OPEN NOW / Urgent / Featured).
- [ ] Always design **loading / empty / error** states on-brand; validate inputs with inline
      `#BA1A1A` error text; never surface raw exceptions.
- [ ] Gate content/actions by the active **role** (Student / Staff / Admin).

---

## 5. New-feature request template (fill & paste with the Master Prompt)

```
FEATURE NAME: <<e.g. "Grades & Transcript">>
ROLE(S): <<Student | Staff | Admin>>
ENTRY POINT: <<from which existing screen / nav item>>
GOAL: <<one sentence: what the user accomplishes>>
SCREENS NEEDED:
  - <<Screen 1: list/overview — which archetype from §3 (dashboard / list / detail / chat / map)>>
  - <<Screen 2: detail — ...>>
KEY DATA SHOWN: <<fields, e.g. course, grade, credits, GPA trend>>
ACTIONS: <<primary (navy) + secondary (cyan/outline) actions>>
STATES TO COVER: loading, empty, error, success
NOTES: <<anything role-specific or edge cases>>
```

**Example (filled):**
> FEATURE NAME: Grades & Transcript · ROLE: Student · ENTRY: Student Dashboard "See All"-style tile
> · GOAL: View per-course grades and overall GPA. · SCREENS: (1) Grades overview = stat card (GPA,
> ▲ trend) + chevron list of course rows colored by performance; (2) Course grade detail = navy
> hero card + breakdown list + outline "Download Transcript". · DATA: course, grade, credits, GPA.
> · ACTIONS: navy "Download Transcript", outline "Filter by Semester". · Cover loading/empty/error.

---

*Generated from the Stitch project "Smart Campus Assistant" (design theme: "Academic Intelligence
System"). Keep this file in sync if the Stitch design system changes.*
