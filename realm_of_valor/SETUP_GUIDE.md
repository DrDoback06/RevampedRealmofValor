# 🚀 Realm of Valor Setup Guide

## 🔧 **API Key Setup**

### 1. Google Maps API Key
You need a valid Google Maps API key to enable:
- Map display
- Places API (POIs)
- Directions API (Navigation)

**Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Directions API
4. Create credentials (API Key)
5. Supply keys via flutter defines (do NOT hardcode):
   - Add to your run command:
     - `--dart-define=MAPS_KEY=YOUR_GOOGLE_MAPS_API_KEY`
     - `--dart-define=OPENWEATHER_API_KEY=YOUR_OPENWEATHER_KEY`
     - `--dart-define=STRAVA_CLIENT_ID=YOUR_STRAVA_CLIENT_ID`
     - `--dart-define=STRAVA_CLIENT_SECRET=YOUR_STRAVA_CLIENT_SECRET`

### 2. Strava API
You already have Strava credentials:
- Client ID: `167388`
- Client Secret: `61689135684e7ca1668a49623ab31b493580f0ad`

### 3. OpenWeatherMap API
You already have the key: `6607a000b24b386d7433a40ff4cc068c`

### 4. AllTrails API
You need to get an API key from AllTrails for trail data.

## 🔥 **Firebase Setup**

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add your app (Android/iOS/Web)

### 2. Firestore Database
1. In Firebase Console, go to Firestore Database
2. Create database in test mode (for development)
3. Deploy security rules:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

### 3. Authentication
1. In Firebase Console, go to Authentication
2. Enable Email/Password authentication
3. Add test users if needed

### 4. Update Firebase Config
Replace the Firebase config in your app with the actual config from Firebase Console.

## 🗺️ **Trail Database System**

### How It Works
The app now includes a trail database system similar to AllTrails:

1. **Local Trail Database**: Pre-defined trails like Snowdon, Ben Nevis, etc.
2. **OpenStreetMap Integration**: Fetches real trail data from OSM
3. **Trail Quests**: Automatically generates quests from trail data

### Trail Types Supported
- Hiking trails
- Running routes
- Cycling paths
- Walking routes
- Mountain biking trails

### Trail Data Includes
- Distance and elevation
- Difficulty levels
- Trail types and tags
- Start/end locations
- Waypoints
- Ratings and reviews

## 🎮 **Quest System Improvements**

### New Quest Types
1. **Trail Quests**: Based on real trail data
2. **Enhanced Enemy Quests**: More enemy types and variants
3. **Exploration Quests**: Ancient ruins, hidden caves, etc.
4. **POI Quests**: Based on real Points of Interest

### Quest Persistence
- Quests are saved to Firebase
- Local fallback if Firebase fails
- Quest progress tracking

## 🚀 **Running the App**

### 1. Fix API Keys
Replace the placeholder API keys in `lib/core/config.dart` with your real keys.

### 2. Deploy Firebase
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 3. Run the App
```bash
flutter run -d chrome \
  --dart-define=MAPS_KEY=YOUR_GOOGLE_MAPS_API_KEY \
  --dart-define=OPENWEATHER_API_KEY=YOUR_OPENWEATHER_KEY \
  --dart-define=STRAVA_CLIENT_ID=YOUR_STRAVA_CLIENT_ID \
  --dart-define=STRAVA_CLIENT_SECRET=YOUR_STRAVA_CLIENT_SECRET
```

## 🔍 **Troubleshooting**

### API Key Issues
- **"Failed to fetch" errors**: Check if API key is valid and APIs are enabled
- **"Quota exceeded"**: Check Google Cloud Console for usage limits
- **"Permission denied"**: Check API restrictions in Google Cloud Console

### Firebase Issues
- **"Permission denied"**: Deploy Firestore rules
- **"User not authenticated"**: Enable Firebase Authentication
- **"Project not found"**: Check Firebase project configuration

### Location Issues
- **Mock location**: Check browser location permissions
- **No GPS**: Ensure location services are enabled

## 📱 **Features Working**

✅ **Map Display**: Fantasy-themed map with quest markers
✅ **Quest Generation**: Random, POI, and trail-based quests
✅ **Quest Persistence**: Firebase integration with local fallback
✅ **Trail Database**: Real trail data from OSM and local database
✅ **Navigation**: Route calculation (with mock fallback)
✅ **Quest UI**: Beautiful quest acceptance dialogs
✅ **Enemy Movement**: Patrolling enemies with different speeds
✅ **Quest Variety**: 20+ enemy types, 18+ item types, quest variants

## 🎯 **Next Steps**

1. **Get Real API Keys**: Replace placeholders with actual keys
2. **Deploy Firebase**: Set up Firebase project and deploy rules
3. **Test Trail System**: Verify trail quests are working
4. **Add More Trails**: Expand the local trail database
5. **Improve OSM Integration**: Better trail data parsing

## 📞 **Support**

If you encounter issues:
1. Check the console logs for error messages
2. Verify API keys are correct
3. Ensure Firebase is properly configured
4. Check browser permissions for location

The app will work with mock data even if APIs fail, but for full functionality, you need the real API keys and Firebase setup.
