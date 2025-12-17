import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConstants {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  /// Default, branded deep-link for OAuth callbacks.
  /// Make sure this exact value is added to Supabase Redirect URLs and
  /// to Google Cloud OAuth authorized redirect URIs.
  static const String defaultMobileRedirect = 'mayorexchange://login-callback';

  /// Optional redirect URL used for OAuth (e.g. Google sign-in).
  /// Configure this in your Supabase project and add it to the `.env` file
  /// as SUPABASE_REDIRECT_URL if you want to override the default.
  static String? get supabaseRedirectUrl =>
      dotenv.env['SUPABASE_REDIRECT_URL']?.isNotEmpty == true
          ? dotenv.env['SUPABASE_REDIRECT_URL']!.trim()
          : null;

  /// Resolves to the branded deep-link unless an override is provided.
  static String get effectiveRedirectUrl =>
      supabaseRedirectUrl ?? defaultMobileRedirect;
}
