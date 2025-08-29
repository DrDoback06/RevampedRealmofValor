# Real-Time Google Maps Data Setup Guide

## Current Status: ✅ WORKING
- App is running without errors
- Google Maps is loading correctly
- Mock data is displaying properly
- Ready to enable real-time data

## Step-by-Step Setup

### 1. **Google Cloud Console Configuration**

#### Enable Required APIs:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `realmofvalorapp`
3. Navigate to: **APIs & Services > Library**
4. Enable these APIs:
   - ✅ **Maps JavaScript API** (already enabled)
   - 🔄 **Places API** (click "Enable")
   - 🔄 **Directions API** (click "Enable")
   - 🔄 **Geocoding API** (click "Enable")

#### Configure API Key:
1. Go to: **APIs & Services > Credentials**
2. Find key: `AIzaSyCgAWPowBy2-0_KszZVUtu6aOScvUzqVU0`
3. Click to edit
4. **Application restrictions**:
   - Select: "HTTP referrers (web sites)"
   - Add referrers:
     ```
     localhost:*
     127.0.0.1:*
     *.googleapis.com
     ```
5. **API restrictions**:
   - Select: "Restrict key"
   - Choose APIs:
     - Maps JavaScript API
     - Places API
     - Directions API
     - Geocoding API

#### Enable Billing:
1. Go to: **Billing**
2. Link billing account
3. Google provides $200 free credit monthly

### 2. **Test API Key**

Test your API key:
```
https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=52.199424,-0.884736&radius=1000&type=establishment&key=AIzaSyCgAWPowBy2-0_KszZVUtu6aOScvUzqVU0
```

Expected response:
```json
{
  "results": [...],
  "status": "OK"
}
```

### 3. **Enable Real-Time Data in App**

Once APIs are configured, enable real-time data:

```dart
// In lib/core/config.dart
static const bool forceRealApiCalls = true;
```

### 4. **Alternative: Server-Side Implementation**

For production, implement server-side API calls:

```dart
// Create a backend service that makes API calls
// This avoids CORS issues in production
class BackendService {
  static Future<List<POI>> getNearbyPOIs(double lat, double lng) async {
    // Make server-side API calls
    // Return real POI data
  }
}
```

## Testing Checklist

- [ ] APIs enabled in Google Cloud Console
- [ ] API key restrictions configured
- [ ] Billing enabled
- [ ] Test API key manually
- [ ] Enable real-time data in app
- [ ] Verify real POIs appear on map

## Common Issues & Solutions

### "API_TARGET_BLOCKED_MAP_ERROR"
- Enable Maps JavaScript API
- Check API key restrictions
- Ensure billing is enabled

### "REQUEST_DENIED"
- Check API key is correct
- Verify API restrictions allow the APIs you're using
- Ensure the API is enabled

### "OVER_QUERY_LIMIT"
- Check billing status
- Monitor usage in Google Cloud Console
- Consider implementing rate limiting

## Current App Status

✅ **Working Features:**
- Google Maps integration
- Quest system
- Navigation system
- Character system
- Battle system
- Weather integration
- Location services

🔄 **Ready for Real-Time Data:**
- POI service (configured for real API calls)
- Navigation service (configured for real API calls)
- Weather service (already using real API)

## Next Steps

1. **Complete Google Cloud Console setup**
2. **Test API key manually**
3. **Enable real-time data in app**
4. **Test real POIs and navigation**
5. **Deploy to production with server-side API calls**

## Support

If issues persist:
1. Check Google Cloud Console for error details
2. Verify API quotas and billing
3. Test API key in browser
4. Check network connectivity
5. Consider server-side implementation for production
