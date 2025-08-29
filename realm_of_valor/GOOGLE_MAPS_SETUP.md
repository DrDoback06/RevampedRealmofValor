# Google Maps API Setup Guide

## Current Issues
- API Target Blocked Error
- Places API calls failing
- App falling back to mock data

## Step-by-Step Fix

### 1. **Enable Required APIs in Google Cloud Console**

Go to [Google Cloud Console](https://console.cloud.google.com/) and enable these APIs:

1. **Maps JavaScript API**
   - Navigate to: APIs & Services > Library
   - Search for "Maps JavaScript API"
   - Click "Enable"

2. **Places API**
   - Search for "Places API"
   - Click "Enable"

3. **Geocoding API**
   - Search for "Geocoding API"
   - Click "Enable"

### 2. **Configure API Key Restrictions**

1. Go to: APIs & Services > Credentials
2. Find your API key (do not commit it to source control)
3. Click on the key to edit
4. Under "Application restrictions":
   - Select "HTTP referrers (web sites)"
   - Add these referrers:
     ```
     localhost:*
     127.0.0.1:*
     *.googleapis.com
     ```
5. Under "API restrictions":
   - Select "Restrict key"
   - Select these APIs:
     - Maps JavaScript API
     - Places API
     - Geocoding API

### 3. **Enable Billing**

1. Go to: Billing
2. Link a billing account to your project
3. Google provides $200 free credit monthly

### 4. **Test API Key**

Test your API key with this URL (replace YOUR_API_KEY):
```
https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=52.199424,-0.884736&radius=1000&type=establishment&key=YOUR_API_KEY
```

Expected response:
```json
{
  "results": [...],
  "status": "OK"
}
```

### 5. **Common Error Solutions**

#### "API_TARGET_BLOCKED_MAP_ERROR"
- Enable Maps JavaScript API
- Check API key restrictions
- Ensure billing is enabled

#### "REQUEST_DENIED"
- Check API key is correct
- Verify API restrictions allow the APIs you're using
- Ensure the API is enabled

#### "OVER_QUERY_LIMIT"
- Check billing status
- Monitor usage in Google Cloud Console
- Consider implementing rate limiting

### 6. **Alternative: Create New API Key**

If the current key has issues:

1. Go to: APIs & Services > Credentials
2. Click "Create Credentials" > "API Key"
3. Copy the new key
4. Provide the new key at build time using flutter defines and avoid hardcoding in files:
   - Example: `flutter run --dart-define=MAPS_KEY=YOUR_KEY`

### 7. **Debug Mode**

The app now has enhanced debugging. Run with:
```bash
flutter run --debug
```

Look for these debug messages:
- `POIService: URL: ...`
- `POIService: Response status: ...`
- `POIService: API Status: ...`

### 8. **Force Real API Calls**

For development (especially on web), you may prefer mock data. To enable real API calls in the app, set:

```dart
// In lib/core/config.dart via --dart-define
// FORCE_REAL_API_CALLS=true
```

## Testing Checklist

- [ ] APIs enabled in Google Cloud Console
- [ ] API key restrictions configured
- [ ] Billing enabled
- [ ] Test API key manually
- [ ] Run app and check debug logs
- [ ] Verify real POIs appear on map

## Support

If issues persist:
1. Check Google Cloud Console for error details
2. Verify API quotas and billing
3. Test API key in browser
4. Check network connectivity
