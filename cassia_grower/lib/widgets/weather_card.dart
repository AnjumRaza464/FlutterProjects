import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sindh_districts.dart';
import '../l10n/app_strings.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// "Today's weather" card for the home screen.
///
/// The grower picks their district once (remembered on the phone); the card
/// then shows the current weather, a 3-day forecast and simple spraying
/// advice, using the free Open-Meteo service.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  static const _prefKey = 'wx_district';
  final _service = WeatherService();

  // Kept across rebuilds (one run of the app) so switching tabs doesn't
  // re-hit the network. Fresh for 30 minutes.
  static String? _cachedDistrict;
  static Weather? _cached;
  static DateTime? _cachedAt;

  String? _district;
  Weather? _weather;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() => _district = saved);
        _load();
      }
    } catch (_) {/* first run / no storage: just show the picker */}
  }

  Future<void> _load() async {
    final d = _district;
    if (d == null) return;

    if (_cachedDistrict == d &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 30)) {
      setState(() {
        _weather = _cached;
        _loading = false;
        _error = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final w = await _service.fetch(d);
      _cachedDistrict = d;
      _cached = w;
      _cachedAt = DateTime.now();
      if (!mounted) return;
      setState(() {
        _weather = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _pickDistrict() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DistrictSheet(current: _district),
    );
    if (chosen == null) return;
    setState(() => _district = chosen);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, chosen);
    } catch (_) {}
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143D20), AppColors.greenLight],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('☀️ ${s.todaysWeather}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
              if (_district != null)
                TextButton(
                  onPressed: _pickDistrict,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFF1D98F),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero),
                  child: Text(s.change,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _body(s),
        ],
      ),
    );
  }

  Widget _body(AppStrings s) {
    if (_district == null) {
      // No district chosen yet: a tap target that opens the picker.
      return InkWell(
        onTap: _pickDistrict,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(s.yourDistrict,
                    style: const TextStyle(color: Color(0xCCFFFFFF))),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
      );
    }
    if (_loading) {
      return const SizedBox(
        height: 96,
        child: Center(
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
      );
    }
    if (_error || _weather == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.weatherUnavailable,
              style: const TextStyle(color: Color(0xE6FFFFFF))),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _load,
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF1D98F),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero),
            child: Text(s.change),
          ),
        ],
      );
    }
    return _WeatherBody(weather: _weather!, district: _district!, s: s);
  }
}

/// The filled-in weather content: current conditions, three stats, the
/// forecast row and the spraying note.
class _WeatherBody extends StatelessWidget {
  const _WeatherBody(
      {required this.weather, required this.district, required this.s});

  final Weather weather;
  final String district;
  final AppStrings s;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final (emoji, label) = Weather.describe(weather.weatherCode);

    Widget stat(String top, String value) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(top,
                    style: const TextStyle(
                        color: Color(0xB3FFFFFF), fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );

    Widget day(DayForecast d) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(_dayNames[d.date.weekday - 1],
                    style: const TextStyle(
                        color: Color(0xB3FFFFFF), fontSize: 11)),
                const SizedBox(height: 2),
                Text('${d.maxC.round()}° / ${d.minC.round()}°',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${weather.tempC.round()}°C',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${s.data(district)} · ${s.data(label)}',
                      style: const TextStyle(color: Color(0xCCFFFFFF))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(children: [
          stat(s.humidity, '${weather.humidity}%'),
          stat(s.wind, '${weather.windKmh.round()} km/h'),
          stat(s.rainChance, '${weather.rainChance}%'),
        ]),
        if (weather.days.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [for (final d in weather.days) day(d)]),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weather.badForSpraying ? '⚠️ ' : '✅ ',
                  style: const TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  weather.badForSpraying ? s.sprayBad : s.sprayOk,
                  style: const TextStyle(
                      color: Color(0xE6FFFFFF), fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A bottom sheet listing the districts to choose from.
class _DistrictSheet extends StatelessWidget {
  const _DistrictSheet({this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(s.chooseYourDistrict,
                    style: TextStyle(
                        color: c.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sindhDistricts.length,
                itemBuilder: (context, i) {
                  final d = sindhDistricts[i];
                  final selected = d == current;
                  return ListTile(
                    title: Text(s.data(d),
                        style: TextStyle(
                            color: c.ink,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500)),
                    trailing: selected
                        ? Icon(Icons.check, color: c.green)
                        : null,
                    onTap: () => Navigator.of(context).pop(d),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
