/// Build-time configuration, passed with
/// `flutter run --dart-define-from-file=config/development.json`.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String onesignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'ASAH');
  static const String clientName = 'Juta Berlian Culinary';

  /// Storage bucket for photos and PDFs (see supabase/migrations/*_app_support.sql).
  static const String mediaBucket = 'asah-media';

  /// media_files.bucket value for videos hosted on Cloudflare Stream.
  static const String streamBucket = 'cloudflare-stream';

  /// Indonesian numbers by default (sign-in screen prefix).
  static const String defaultDialCode = '+62';

  static bool get isPushConfigured => onesignalAppId.isNotEmpty;

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY are not set. '
        'Run with --dart-define-from-file=config/development.json',
      );
    }
  }
}
