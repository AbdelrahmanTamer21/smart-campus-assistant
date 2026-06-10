# Smart Campus Assistant

Flutter mobile app (Provider + go_router) backed by Firebase project **`smart-campus-asst-8391`**.

For full setup, iOS signing, Firebase, and emulator instructions, see **[SETUP.md](SETUP.md)**.

## Quick run

```bash
# Production (Cloud Functions deployed — FCM + in-app notifications via server)
flutter run -d chrome
# or on a connected iPhone:
flutter run -d <device-id>

# Local emulators (free dev, no Blaze billing)
flutter run -d chrome --dart-define=USE_EMULATOR=true
```

**Cloud Functions** are deployed on project `smart-campus-asst-8391` (Blaze). Production runs use server-side notifications automatically (no `CLIENT_FANOUT` flag needed).

See **[SETUP.md](SETUP.md)** for emulator setup, Blaze billing notes, and role-claim script.

## Demo accounts

Sign in with the **University ID** (not email). All seeded accounts share the same password.

**Password:** `campus123`

| Role | Name | University ID |
|------|------|---------------|
| Student | Alex Morgan | `202400123` |
| Faculty | Prof. Wilson | `900100` |
| Admin | Admin Console | `500001` |

### QR activation demo

Unclaimed record **Jordan Lee** (`202400999`) — activate with token:

```
DEMO-ACTIVATE-001
```

Paste it on the **Scan QR / Activation Code** screen, or scan it as a QR code, then set a password.
