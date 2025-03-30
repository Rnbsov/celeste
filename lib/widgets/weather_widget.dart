import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  String? _error;
  final String _apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadWeatherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // First try to load cached weather data
      final cachedData = await _getCachedWeather();
      if (cachedData != null) {
        if (mounted) {
          setState(() {
            _weatherData = cachedData;
            _isLoading = false;
          });
        }
      }

      // Get current location
      final position = await _determinePosition();

      // Fetch weather data from API
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the weather data
        await _cacheWeatherData(data);

        if (mounted) {
          setState(() {
            _weatherData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load weather data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedWeatherString = prefs.getString('cached_weather');

      if (cachedWeatherString != null) {
        final cachedWeather = json.decode(cachedWeatherString);
        final timestamp = cachedWeather['timestamp'] as int;

        // Check if the cached data is less than 30 minutes old
        if (DateTime.now().millisecondsSinceEpoch - timestamp <
            30 * 60 * 1000) {
          return cachedWeather['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheWeatherData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await prefs.setString('cached_weather', json.encode(cacheData));
    } catch (e) {
      // Silently fail if caching doesn't work
    }
  }

  /// Determine the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show dialog to enable them
      if (mounted) {
        await _showLocationServiceDialog();
      }
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show message
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, show settings dialog
      if (mounted) {
        await _showPermissionDeniedDialog();
      }
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _showLocationServiceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text(
            "Please enable location services to see weather in your area. Would you like to open settings now?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermissionDeniedDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Denied"),
          content: const Text(
            "Location permissions are denied permanently. Please enable them in app settings to see weather information.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  LinearGradient _getBackgroundGradient(String condition, bool isDay) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return isDay
            ? const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            )
            : const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            );
      case 'clouds':
        return isDay
            ? const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
            )
            : const LinearGradient(
              colors: [Color(0xFF2E3B2E), Color(0xFF3E5F41)],
            );
      case 'rain':
      case 'drizzle':
        return const LinearGradient(
          colors: [Color(0xFF546E7A), Color(0xFF78909C)],
        );
      case 'thunderstorm':
        return const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF455A64)],
        );
      case 'snow':
        return const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        );
      case 'mist':
      case 'fog':
      case 'haze':
        return const LinearGradient(
          colors: [Color(0xFF90A4AE), Color(0xFFB0BEC5)],
        );
      default:
        return isDay
            ? const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
            )
            : const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            );
    }
  }

  Color _getTextColor(String condition, bool isDay) {
    if (condition.toLowerCase() == 'snow' ||
        condition.toLowerCase() == 'mist' ||
        condition.toLowerCase() == 'fog' ||
        condition.toLowerCase() == 'haze') {
      return Colors.black87;
    }
    return isDay ? Colors.black87 : Colors.white;
  }

  // Weather emoji getter
  String _getWeatherEmoji(String iconCode) {
    bool isDay = iconCode.contains('d');

    switch (iconCode.substring(0, 2)) {
      case '01':
        return isDay ? '☀️' : '🌙';
      case '02':
        return '⛅';
      case '03':
      case '04':
        return '☁️';
      case '09':
        return '🌧️';
      case '10':
        return isDay ? '🌦️' : '🌧️';
      case '11':
        return '⛈️';
      case '13':
        return '❄️';
      case '50':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state - more compact
    if (_isLoading) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE0E0E0),
                Color(0xFFE8F5E9),
              ], // Slight green tint
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF4CAF50),
              ), // Green color
            ),
          ),
        ),
      );
    }

    // Error state - more compact
    if (_error != null || _weatherData == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE8F5E9),
                Color(0xFFE0E0E0),
              ], // Slight green tint
            ),
          ),
          child: Row(
            children: [
              Icon(
                _error?.contains('permission') == true
                    ? Icons.location_off
                    : Icons.cloud_off,
                size: 32,
                color: Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error?.contains('permission') == true
                          ? 'Location permission required'
                          : _error ?? 'Weather data unavailable',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _error?.contains('permission') == true
                              ? () => Geolocator.openAppSettings()
                              : _loadWeatherData,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(30, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF388E3C), // Green text
                      ),
                      child: Text(
                        _error?.contains('permission') == true
                            ? 'Open Settings'
                            : 'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Weather data display - more compact
    final weather = _weatherData!;
    final temp = (weather['main']['temp'] as num).toStringAsFixed(1);
    final condition = weather['weather'][0]['main'];
    final iconCode = weather['weather'][0]['icon'];
    final city = weather['name'];
    final humidity = weather['main']['humidity'];
    final windSpeed = weather['wind']['speed'];

    final isDay = iconCode.contains('d');
    final textColor = _getTextColor(condition, isDay);
    final bgGradient = _getBackgroundGradient(condition, isDay);

    _animationController.forward();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: bgGradient,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Left side: Temperature and condition
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: textColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              temp,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          condition,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side: Weather icon and stats
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Weather emoji with refresh functionality
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getWeatherEmoji(iconCode),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _loadWeatherData,
                            child: Icon(
                              Icons.refresh,
                              size: 16,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Humidity and wind in row
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$humidity%',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.air,
                            size: 12,
                            color: textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$windSpeed m/s',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      // Removed the separate update button that was causing overflow
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
