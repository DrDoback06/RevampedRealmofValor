# Simple Google Maps Setup Guide

## Quick Setup for Realm of Valor

### Step 1: Enable APIs
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Enable these APIs:
   - **Maps JavaScript API**
   - **Places API**
   - **Geocoding API**
   - **Directions API**

### Step 2: Create API Key
1. Go to "Credentials" in the left sidebar
2. Click "Create Credentials" → "API Key"
3. Copy the generated API key

### Step 3: Configure API Key Restrictions
1. Click on your API key to edit it
2. Under "Application restrictions":
   - Select "HTTP referrers (web sites)"
   - Add these referrers:
     ```
     localhost:*
     127.0.0.1:*
     *.googleapis.com
     ```
3. Under "API restrictions":
   - Select "Restrict key"
   - Select all the APIs you enabled in Step 1

### Step 4: Enable Billing
1. Go to "Billing" in the left sidebar
2. Link a billing account to your project
3. Google Maps has a generous free tier (usually $200/month credit)

### Step 5: Test Your Setup
1. The app should now work with real Google Maps data
2. If you see errors, check the browser console for specific error messages

## Troubleshooting

### Common Errors:
- **`RefererNotAllowedMapError`**: Add `localhost:*` to your HTTP referrers
- **`API_TARGET_BLOCKED_MAP_ERROR`**: Make sure all required APIs are enabled
- **`REQUEST_DENIED`**: Check that billing is enabled
- **`OVER_QUERY_LIMIT`**: You've exceeded the free tier (unlikely for testing)

### For Development:
- The app currently uses mock data for web to avoid CORS issues
- Real Google Maps data will work once you complete this setup
- The map widget itself uses the Google Maps JavaScript API directly

### Current API Key:
The app is configured to use: `AIzaSyCgAWPowBy2-0_KszZVUtu6aOScvUzqVU0`

## Next Steps
Once setup is complete:
1. The map will show real POIs (pubs, gyms, museums)
2. Navigation will work with real routes
3. Weather data will be accurate
4. All features will use real-time data instead of mock data

## Support
If you encounter issues:
1. Check the browser console for error messages
2. Verify all APIs are enabled
3. Ensure billing is set up
4. Confirm HTTP referrers are correct
