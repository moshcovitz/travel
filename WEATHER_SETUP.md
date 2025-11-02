# Weather API Setup Guide

The travel app includes a weather feature that displays current weather conditions for your trip's current location. This feature uses the OpenWeatherMap API.

## Getting Your Free API Key

1. **Sign up for OpenWeatherMap**
   - Go to [https://openweathermap.org/api](https://openweathermap.org/api)
   - Click "Sign Up" (top right)
   - Create a free account

2. **Get Your API Key**
   - After signing in, go to [https://home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys)
   - Your default API key will be shown, or you can create a new one
   - Copy your API key (it looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

3. **Activate Your API Key**
   - New API keys can take up to 2 hours to activate
   - You'll receive an email when it's ready

## Adding the API Key to Your App

Open the file `lib/services/weather_service.dart` and replace the placeholder with your actual API key:

```dart
// Line 13-14
static const String _apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key
```

Change it to:

```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'; // Your actual key
```

## How It Works

- The weather tile appears on the trip detail screen
- It shows weather for the **most recent location** in your trip
- Weather data is cached for 30 minutes to reduce API calls
- If you don't configure an API key, the weather tile won't appear

## Features Displayed

- **Temperature** (Celsius with feels-like temperature)
- **Weather condition** (Clear, Cloudy, Rainy, etc.)
- **Location name** (based on your coordinates)
- **Additional details**:
  - Humidity percentage
  - Wind speed (m/s)
  - Atmospheric pressure (hPa)
- **Weather icon** (color-coded by condition)

## Free Tier Limits

The free OpenWeatherMap plan includes:
- 1,000 API calls per day
- 60 calls per minute
- Current weather data
- 5 day / 3 hour forecast

This is more than enough for personal travel tracking!

## Troubleshooting

**Weather tile doesn't appear:**
- Make sure you've added your API key
- Verify your trip has at least one location tracked
- Check that your API key is activated (wait 2 hours after creation)

**"Weather data unavailable" message:**
- Check your internet connection
- Verify your API key is correct
- Check API key is activated
- View the app logs for detailed error messages

**API key security:**
- For a production app, use environment variables or secure storage
- Don't commit your API key to public repositories
- The current implementation is suitable for personal use

## Optional: Using Environment Variables

For better security in production:

1. Add `flutter_dotenv` to `pubspec.yaml`
2. Create a `.env` file with: `WEATHER_API_KEY=your_key_here`
3. Add `.env` to `.gitignore`
4. Load the key in `weather_service.dart`:
   ```dart
   static final String _apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
   ```

This prevents accidentally committing your API key to version control.
