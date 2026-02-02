/// Centralized API configuration.
///
/// For local testing only. Avoid hardcoding production secrets/URLs in apps.
const String apiBaseUrl = 'http://192.168.90.101:5000';

/// Derived endpoints.
const String googleAuthEndpoint = '$apiBaseUrl/auth/google';
