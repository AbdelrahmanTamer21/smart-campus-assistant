# Smart Campus Assistant — Setup & Run

Flutter app (Provider + go_router) on **Firebase** project **`smart-campus-asst-8391`**
(already wired via `lib/firebase_options.dart`). Role is authoritative from the **JWT custom
claim** `role`; there is no role-picker screen.

> **Status — backend is LIVE and seeded.** Already done: GCP APIs enabled · Email/Password auth
> enabled · Firestore (Native) database created · security rules + indexes deployed · data seeded ·
> three accounts created with `role` claims set · one unclaimed record + activation token.
> **Just run the app** (step 6). Re-seeding is only needed if you wipe the project.
> Steps 1–4 below document what was done; step 5 (Functions) is optional and needs the Blaze plan.

## 1. Enable Firebase services (one-time, console)
Open the console: <https://console.firebase.google.com/project/smart-campus-asst-8391>
1. **Authentication → Get started → Sign-in method → Email/Password → Enable.**
2. **Firestore Database → Create database →** start in **Test mode** (so the seed can write), location e.g. `nam5`.

> No Firebase **Storage** is required (it needs the paid plan). Profile photos are stored as a small
> base64 string in the Firestore user doc; course resources are metadata only.

## 2. Seed demo data (registrar import), while rules are still open
```bash
flutter run -d chrome --dart-define=SEED=true   # let it reach the login screen, then stop
```
This creates courses, today's classes, assignments, events, announcements, map pins, admin stats,
three **activated** accounts, and one **unclaimed** record + a demo activation token.

**Seeded logins** (password `campus123`):
| Role | University ID |
|------|----------------|
| Student (Alex Morgan) | `202400123` |
| Faculty (Prof. Wilson) | `900100` |
| Admin (Admin Console) | `500001` |

**QR activation demo:** unclaimed record *Jordan Lee* (`202400999`), token **`DEMO-ACTIVATE-001`**
(paste it on the Scan-QR screen's "paste code" field, or encode it as a QR).

## 3. Lock down security rules (after seeding)
```bash
firebase deploy --only firestore:rules,firestore:indexes --project=smart-campus-asst-8391
```

## 4. Role claims (so staff/admin can write under locked rules)
The locked rules enforce writes via the `role` **JWT claim**. Claims are set automatically by the
`redeemSignupToken` Cloud Function on QR activation. For the **seeded** accounts (created directly),
grant claims once — either:
- **Deploy Functions** (needs the **Blaze** plan) and activate accounts via QR going forward, or
- Run the one-off admin script: `node tool/set_claims.mjs` (needs a service-account key — see the
  file header). Sets `role` for the three seeded accounts.

Students need **no** claim (their reads/writes are self-scoped), so the student experience works
immediately after steps 1–3.

> Steps 1–4 below document what was done. **Cloud Functions are deployed** (Blaze) — see §5.

## Blaze plan & deployed Functions

Project **`smart-campus-asst-8391`** is on the **Blaze** (pay-as-you-go) plan. For a small test app with few users, monthly cost is typically **$0** (within free tiers). Set a budget alert in [Google Cloud Billing](https://console.cloud.google.com/billing).

**Deployed functions** (as of last deploy):

| Function | Trigger | Region |
|----------|---------|--------|
| `redeemSignupToken` | HTTPS callable | us-central1 |
| `askCampusAi` | HTTPS callable | us-central1 |
| `onAnnouncementCreated` | Firestore create | europe-west1 |
| `onClassChanged` | Firestore update | europe-west1 |
| `onAssignmentWritten` | Firestore create | europe-west1 |

**Redeploy** after changing `functions/`:

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions,firestore:rules --project=smart-campus-asst-8391
```

First deploy after enabling Blaze may fail with Eventarc IAM errors — wait 2–3 minutes and run deploy again.

**Production app run** (no emulator flags):

```bash
flutter run -d <device-id>
```

The app skips client-side notification fan-out in production (`AppConfig.serverNotifications` defaults on). Functions write in-app notifications and send FCM.

## 5. Notifications
The **F10 change-notification system works without Functions/billing**: when staff/admin change a
class room/status, edit a deadline, or publish an announcement, the app **writes the in-app
notification straight into each affected student's `users/{id}/notifications`** (gated by the `role`
JWT claim in the security rules). Students stream these live, so the **bell badge + Notifications
inbox update in real time**. No Blaze plan required.

What this free path does **not** include: a system push banner when the app is **closed**. Options for
that, if you want it later:
- **Free external sender** — a tiny serverless endpoint on a free tier (Cloudflare Workers / Render /
  Supabase Edge) that calls the FCM HTTP v1 API; the app pings it after a write.
- **Cloud Functions** (`functions/` is already written: `redeemSignupToken`, the F10 triggers, and a
  stub `askCampusAi`) — needs the **Blaze** plan (which has a free usage tier but requires a card):
  ```bash
  cd functions && npm install && npm run build && cd ..
  firebase deploy --only functions --project=smart-campus-asst-8391
  ```
  If you deploy Functions, remove the client-side `fanOutTo*` calls to avoid double notifications.

QR activation also works without Functions (client-side fallback in `AuthService`), and the AI uses
the on-device scripted engine — so the whole app runs fully on the **free Spark plan**.

## 6. Run
```bash
flutter run -d chrome      # or an Android device/emulator for camera/GPS/biometric/push
```

## 7. Real FCM push on a local Android emulator (free, no Blaze)
Running the Cloud Functions in the **local emulator is free** — they trigger on the local Firestore
and call **real** FCM (FCM itself is never emulated), so you get genuine OS push banners.

**Prereqs**
- An **Android emulator image with Google Play** (Play Store icon). The iOS simulator can't receive push.
- A service-account key so the Functions emulator can make real FCM calls:
  Console → Project settings → Service accounts → **Generate new private key** → save as
  `functions/sa-key.json` (gitignored).

**Build functions once**
```bash
cd functions && npm install && npm run build && cd ..
```

**Start the emulators** (Auth :9099, Firestore :8080, Functions :5001):
```bash
GOOGLE_APPLICATION_CREDENTIALS=functions/sa-key.json \
  firebase emulators:start --only auth,firestore,functions --project=smart-campus-asst-8391
```

**Run the app against the emulators** (Android emulator reaches the host at `10.0.2.2`):
```bash
# first run seeds the emulator's Firestore + Auth:
flutter run -d emulator-5554 --dart-define=USE_EMULATOR=true --dart-define=EMU_HOST=10.0.2.2 --dart-define=SEED=true
# subsequent runs:
flutter run -d emulator-5554 --dart-define=USE_EMULATOR=true --dart-define=EMU_HOST=10.0.2.2
```
With `USE_EMULATOR=true`, the app turns **off** its client-side in-app fan-out and lets the Functions
emulator be the single source — it both writes the in-app notification docs **and** sends the FCM push.

**Test it:** sign in as staff (`900100`/`campus123`), change a class room or post a deadline →
a signed-in student on the emulator gets a **system notification banner** (foreground shown via a
local notification, background/closed shown by the OS) that deep-links into the app.

> Quick manual check without Functions: Console → **Cloud Messaging → Send test message** to a device
> FCM token (printed in logs on login) — also free.

## 8. Running on a physical iPhone
iOS is now Firebase-configured (`ios/Runner/GoogleService-Info.plist` + the `ios` entry in
`firebase_options.dart`). To run on your iPhone:
```bash
open ios/Runner.xcworkspace      # in Xcode: Signing & Capabilities →
                                 #   pick your Apple ID team, set a unique Bundle Identifier
flutter run -d <your-iphone>     # trust the developer profile on the device when prompted
```
Everything works on a **free Apple ID**: auth, Firestore, offline, GPS, camera, **Face ID**, the
in-app bell/inbox, and local-notification banners while the app is open.

**Remote push on iOS is the one paid piece.** Apple only issues **APNs** credentials with the paid
**Apple Developer Program ($99/yr)** — a free Apple ID literally can't add the *Push Notifications*
capability. With the paid program:
1. Xcode → Signing & Capabilities → add **Push Notifications** + **Background Modes → Remote notifications**.
2. Apple Developer → Keys → create an **APNs Auth Key (.p8)**.
3. Firebase Console → Project settings → Cloud Messaging → **Apple app config → upload the .p8** (+ Key ID, Team ID).

Then FCM push works on the iPhone too. Until then, `getToken()` just returns null on iOS (handled
gracefully) — use the **free Android-emulator path (§7)** for push testing.

## Notes
- **Offline-first:** Firestore persistence is on; an offline banner shows when disconnected and
  writes queue + replay on reconnect.
- **Device features** (QR scan, biometric, GPS, push) are fully functional on Android/iOS and degrade
  gracefully on Chrome/macOS. The campus map is a stylized pure-widget canvas, so it always renders.
- **AI guardrails:** on-topic only, prompt-injection resistant, and scoped to the signed-in user's
  own data (see `lib/services/ai_service.dart`).
- iOS/macOS weren't configured by `flutterfire` here (the `xcodeproj` Ruby gem was missing). Run
  `sudo gem install xcodeproj` then `flutterfire configure --platforms=ios,macos` to add them.
