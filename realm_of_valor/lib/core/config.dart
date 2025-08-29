class AppConfig {
  // API Keys - Real keys provided by user
  // Note: You need to replace these with your actual API keys
  static const String googleMapsApiKey = 'AIzaSyCgAWPowBy2-0_KszZVUtu6aOScvUzqVU0';
  
  static const String stravaClientId = '167388';
  static const String stravaClientSecret = '61689135684e7ca1668a49623ab31b493580f0ad';
  
  static const String allTrailsApiKey = 'your_alltrails_api_key';
  
  static const String openWeatherApiKey = '6607a000b24b386d7433a40ff4cc068c';
  
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
