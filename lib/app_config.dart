/// Build-time flags.
class AppConfig {
  AppConfig._();

  /// Run against the local Firebase Emulator Suite (Auth + Firestore +
  /// Functions). Enable with: `--dart-define=USE_EMULATOR=true`.
  static const useEmulator = bool.fromEnvironment('USE_EMULATOR');

  /// Emulator host. Android emulators reach the host machine via 10.0.2.2;
  /// everything else uses localhost. Override with `--dart-define=EMU_HOST=...`.
  static const emulatorHost =
      String.fromEnvironment('EMU_HOST', defaultValue: 'localhost');

  /// When server-side notifications are active (Functions emulator or deployed
  /// production Functions), the client must NOT also fan out in-app docs.
  /// Override with `--dart-define=CLIENT_FANOUT=true` to force client-side fan-out.
  static const serverNotifications =
      useEmulator || !bool.fromEnvironment('CLIENT_FANOUT');
}
