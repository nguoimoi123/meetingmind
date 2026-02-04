/// Configure your OpenAI API key here.
/// WARNING: Hardcoding secrets in the app is not secure. Prefer using
/// a secure storage / backend token exchange in production.
/// For local testing only.
const String openAiApiKey =
    String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
