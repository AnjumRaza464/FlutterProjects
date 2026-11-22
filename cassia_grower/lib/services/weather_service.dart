import 'dart:convert';

import 'package:http/http.dart' as http;

/// One day of the short forecast.
class DayForecast {
  const DayForecast({
    required this.date,
    required this.maxC,
    required this.minC,
    required this.rainChance,
  });

  final DateTime date;
  final double maxC;
  final double minC;
  final int rainChance; // %
}

/// Current weather plus a 3-day forecast for one place.
class Weather {
  const Weather({
    required this.tempC,
    required this.humidity,
    required this.windKmh,
    required this.rainChance,
    required this.weatherCode,
    required this.days,
    required this.badForSpraying,
  });

  final double tempC;
  final int humidity; // %
  final double windKmh;
  final int rainChance; // % (today)
  final int weatherCode;
  final List<DayForecast> days;

  /// True when it is a poor time to spray: strong wind, rain now, or a high
  /// chance of rain today. Matches the v5 reference rule.
  final bool badForSpraying;

  /// Weather code → (emoji, short label). Mirrors the reference app.
  static (String, String) describe(int code) {
    if (code == 0) return ('☀️', 'Clear sky');
    if (code < 3) return ('⛅', 'Partly cloudy');
    if (code == 3) return ('☁️', 'Cloudy');
    if (code < 50) return ('🌫️', 'Fog');
    if (code < 70) return ('🌧️', 'Rain');
    if (code >= 95) return ('⛈️', 'Thunderstorm');
    if (code >= 80) return ('🌦️', 'Showers');
    return ('☁️', 'Cloudy');
  }
}

/// Fetches weather from Open-Meteo — a free API that needs no key, so it
/// costs the company nothing to run.
class WeatherService {
  /// Looks up the district (in Pakistan), then fetches its current weather
  /// and a 3-day forecast. Throws on network errors or an unknown place.
  Future<Weather> fetch(String district) async {
    final geoRes = await http.get(Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?count=1&country_code=PK&name=${Uri.encodeComponent(district)}',
    ));
    final geo = jsonDecode(geoRes.body) as Map<String, dynamic>;
    final results = geo['results'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('Place not found: $district');
    }
    final place = results.first as Map<String, dynamic>;
    final lat = place['latitude'];
    final lon = place['longitude'];

    final fcRes = await http.get(Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,precipitation,'
      'weather_code,wind_speed_10m'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&timezone=auto&forecast_days=3',
    ));
    final w = jsonDecode(fcRes.body) as Map<String, dynamic>;
    final cur = w['current'] as Map<String, dynamic>;
    final daily = w['daily'] as Map<String, dynamic>;

    final times = (daily['time'] as List).cast<String>();
    final maxs = daily['temperature_2m_max'] as List;
    final mins = daily['temperature_2m_min'] as List;
    final rains = daily['precipitation_probability_max'] as List;

    final days = <DayForecast>[
      for (var i = 0; i < times.length; i++)
        DayForecast(
          date: DateTime.parse('${times[i]}T12:00'),
          maxC: (maxs[i] as num).toDouble(),
          minC: (mins[i] as num).toDouble(),
          rainChance: ((rains[i] ?? 0) as num).toInt(),
        ),
    ];

    final wind = (cur['wind_speed_10m'] as num).toDouble();
    final precipNow = (cur['precipitation'] as num?)?.toDouble() ?? 0;
    final rainToday = days.isNotEmpty ? days.first.rainChance : 0;

    return Weather(
      tempC: (cur['temperature_2m'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      windKmh: wind,
      rainChance: rainToday,
      weatherCode: (cur['weather_code'] as num).toInt(),
      days: days,
      badForSpraying: wind >= 20 || precipNow > 0 || rainToday >= 50,
    );
  }
}
