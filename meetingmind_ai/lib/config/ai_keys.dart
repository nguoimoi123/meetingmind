import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Local app-side AI config for development.
/// In production, prefer fetching capability from backend instead of shipping keys in the app.
String get openAiApiKey => (dotenv.env['OPENAI_API_KEY'] ?? '').trim();

bool get hasConfiguredOpenAiKey => openAiApiKey.isNotEmpty;
