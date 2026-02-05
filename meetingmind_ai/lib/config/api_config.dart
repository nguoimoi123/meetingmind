/// Centralized API configuration.
///
/// For local testing only. Avoid hardcoding production secrets/URLs in apps.
const String apiBaseUrl = 'http://192.168.88.141:5001';

/// Derived endpoints.
const String googleAuthEndpoint = '$apiBaseUrl/auth/google';
