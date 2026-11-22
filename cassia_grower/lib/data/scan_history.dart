import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_store.dart';

/// One past Crop Doctor diagnosis, as listed under "Recent scans".
class ScanRecord {
  const ScanRecord({
    required this.at,
    required this.crop,
    required this.summary,
  });

  final DateTime at;

  /// The crop the farmer chose; empty when they didn't say.
  final String crop;

  /// The first line or so of the diagnosis, ending in "…" if it was cut.
  final String summary;

  Map<String, dynamic> toMap() => {
        'at': at.millisecondsSinceEpoch,
        'crop': crop,
        'summary': summary,
      };

  static ScanRecord? fromMap(dynamic map) {
    if (map is! Map || map['at'] is! int) return null;
    return ScanRecord(
      at: DateTime.fromMillisecondsSinceEpoch(map['at'] as int),
      crop: (map['crop'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
    );
  }
}

/// The farmer's last few Crop Doctor diagnoses, kept on their own phone
/// (nothing is uploaded). Newest first.
class ScanHistory {
  ScanHistory({LocalStore? store}) : _store = store ?? MemoryStore();

  /// The history kept on this device. Where the phone's storage can't be
  /// reached, the list simply lasts until the app is closed.
  static Future<ScanHistory> open() async {
    try {
      return ScanHistory(
          store: PrefsStore(await SharedPreferences.getInstance()));
    } catch (_) {
      return ScanHistory();
    }
  }

  static const _key = 'doctor_scans';

  /// How many scans are kept.
  static const int max = 5;

  /// How much of a diagnosis is kept as its summary, in characters.
  static const int summaryLength = 90;

  final LocalStore _store;

  List<ScanRecord> get recent {
    try {
      final saved = jsonDecode(_store.read(_key) ?? '[]');
      if (saved is! List) return const [];
      return [for (final item in saved) ?ScanRecord.fromMap(item)];
    } catch (_) {
      return const []; // unreadable history is treated as none
    }
  }

  /// Puts a new scan at the top, dropping the oldest beyond [max].
  Future<void> add({
    required String crop,
    required String summary,
    DateTime? at,
  }) {
    final text = summary.replaceAll(RegExp(r'\s+'), ' ').trim();
    final record = ScanRecord(
      at: at ?? DateTime.now(),
      crop: crop,
      // A summary that had to be cut short says so with "…".
      summary: text.length > summaryLength
          ? '${text.substring(0, summaryLength).trimRight()}…'
          : text,
    );
    final all = [record, ...recent].take(max);
    return _store.write(_key, jsonEncode([for (final r in all) r.toMap()]));
  }
}
