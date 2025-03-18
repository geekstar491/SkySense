import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const WeatherScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _weatherData = "Enter a city to check weather";
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;

  String _getWeatherCondition(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Fog';
      case 48:
        return 'Depositing rime fog';
      case 51:
        return 'Light drizzle';
      case 53:
        return 'Moderate drizzle';
      case 55:
        return 'Dense drizzle';
      case 56:
        return 'Light freezing drizzle';
      case 57:
        return 'Dense freezing drizzle';
      case 61:
        return 'Slight rain';
      case 63:
        return 'Moderate rain';
      case 65:
        return 'Heavy rain';
      case 66:
        return 'Light freezing rain';
      case 67:
        return 'Heavy freezing rain';
      case 71:
        return 'Slight snow fall';
      case 73:
        return 'Moderate snow fall';
      case 75:
        return 'Heavy snow fall';
      case 77:
        return 'Snow grains';
      case 80:
        return 'Slight rain showers';
      case 81:
        return 'Moderate rain showers';
      case 82:
        return 'Violent rain showers';
      case 85:
        return 'Slight snow showers';
      case 86:
        return 'Heavy snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
        return 'Thunderstorm with slight hail';
      case 99:
        return 'Thunderstorm with heavy hail';
      default:
        return 'Unknown weather';
    }
  }

  Future<void> _fetchWeather(String city) async {
    if (city.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // First get coordinates for the city
      final geoResponse = await http.get(
        Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}'),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (geoResponse.statusCode == 200) {
        final geoData = jsonDecode(geoResponse.body);
        final results = geoData['results'] as List<dynamic>?;

        if (results == null || results.isEmpty) {
          setState(() => _weatherData = "City not found!");
          return;
        }

        final latitude = results[0]['latitude'];
        final longitude = results[0]['longitude'];
        final locationName = results[0]['name'];
        final country = results[0]['country'] ?? '';
        final admin1 = results[0]['admin1'] ?? '';

        // Now get weather data
        final weatherResponse = await http.get(
          Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true'),
        ).timeout(const Duration(seconds: 10));

        if (!mounted) return;

        if (weatherResponse.statusCode == 200) {
          final weatherData = jsonDecode(weatherResponse.body);
          final current = weatherData['current_weather'];

          setState(() {
            _weatherData = 
                "📍 $locationName, $admin1 $country\n"
                "🌡️ Temperature: ${current['temperature']}°C\n"
                "🌤️ Conditions: ${_getWeatherCondition(current['weathercode'])}\n"
                "💨 Wind Speed: ${current['windspeed']} km/h";
          });
        } else {
          setState(() => _weatherData = "Weather data error: ${weatherResponse.statusCode}");
        }
      } else {
        setState(() => _weatherData = "Geocoding error: ${geoResponse.statusCode}");
      }
    } on TimeoutException {
      setState(() => _weatherData = "Request timeout!");
    } on http.ClientException {
      setState(() => _weatherData = "Network error!");
    } catch (e) {
      setState(() => _weatherData = "Unexpected error: ${e.runtimeType}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weather App")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: "Enter city (e.g., Tokyo)",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoading
                      ? null
                      : () => _fetchWeather(_cityController.text),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _weatherData,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }
}