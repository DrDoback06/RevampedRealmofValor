class AppConfig {
  // API Keys are supplied via --dart-define or env. Do not hardcode secrets in source.
  static const String googleMapsApiKey = String.fromEnvironment('MAPS_KEY', defaultValue: '');
  static const String stravaClientId = String.fromEnvironment('STRAVA_CLIENT_ID', defaultValue: '');
  static const String stravaClientSecret = String.fromEnvironment('STRAVA_CLIENT_SECRET', defaultValue: '');
  static const String allTrailsApiKey = String.fromEnvironment('ALLTRAILS_API_KEY', defaultValue: '');
  static const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');
  
  // App Settings
  static const bool enableMockData = bool.fromEnvironment(
    'ENABLE_MOCK_DATA',
    defaultValue: false, // Changed to false to force real API calls
  );
  
  static const bool enableFirebasePersistence = bool.fromEnvironment(
    'ENABLE_FIREBASE_PERSISTENCE',
    defaultValue: true,
  );
  
  // API Debug Settings
  static const bool enableApiDebugging = bool.fromEnvironment(
    'ENABLE_API_DEBUGGING',
    defaultValue: true,
  );
  
  static const bool forceRealApiCalls = bool.fromEnvironment(
    'FORCE_REAL_API_CALLS',
    defaultValue: false, // Temporarily disabled for web compatibility
  );
  
  // Quest Settings
  static const int maxActiveQuests = 10;
  static const int maxRandomQuests = 15;
  static const double questGenerationRadius = 0.02; // ~2km
  static const double questCleanupDistance = 0.01; // ~1km
  
  // Location Settings
  static const double defaultLocationLat = 52.232192;
  static const double defaultLocationLng = -0.8912896;
  static const String defaultLocationName = 'Northampton, UK';
  
  // Debug Settings
  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: true,
  );
}
