import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apiBaseUrl {
  final configured = (dotenv.env['API_BASE_URL'] ?? '').trim();
  if (configured.isNotEmpty) {
    return configured;
  }
  return 'http://localhost:5000';
}

String get googleAuthEndpoint => '$apiBaseUrl/auth/google';
