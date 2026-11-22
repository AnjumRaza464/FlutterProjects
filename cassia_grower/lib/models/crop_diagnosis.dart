/// Result of a Crop Doctor diagnosis.
///
/// Mirrors the structured JSON returned by the `diagnoseCrop` Cloud Function
/// (see functions/src/index.ts). Its parts line up with the six cards the
/// screen shows: what is seen, the most likely problem, other possibilities,
/// the cause, treatment and prevention.
///
/// Values coming back over the Firebase platform channel are loosely typed,
/// so parsing is defensive.
class CropDiagnosis {
  final bool isPlant; // false if the photos don't show a plant/crop
  final String cropGuess; // what crop the model thinks it is
  final bool healthy; // appears healthy

  /// 1) The symptoms that can actually be seen in the photos.
  final String observed;

  /// 2) The most likely disease / pest / disorder, how sure the model is
  /// (0–100) and why.
  final String problem;
  final int confidencePercent;
  final String reason;

  /// 3) Up to two other possibilities, each with how to tell it apart.
  final List<String> alternatives;

  /// 4) What is lacking, or the underlying cause.
  final String cause;

  /// 5) What to do, in order.
  final List<String> treatment;

  /// 6) How to avoid it next time.
  final List<String> prevention;

  /// The extra photo or detail that would make the diagnosis surer. Empty
  /// when the photos were clear enough.
  final String needMore;

  /// One short, farmer-friendly sentence.
  final String summary;

  const CropDiagnosis({
    required this.isPlant,
    this.cropGuess = '',
    this.healthy = false,
    this.observed = '',
    this.problem = '',
    this.confidencePercent = 0,
    this.reason = '',
    this.alternatives = const [],
    this.cause = '',
    this.treatment = const [],
    this.prevention = const [],
    this.needMore = '',
    this.summary = '',
  });

  factory CropDiagnosis.fromMap(Map<String, dynamic> map) {
    String str(String key) => (map[key] ?? '').toString().trim();

    List<String> strList(String key) {
      final v = map[key];
      if (v is! List) return const [];
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return CropDiagnosis(
      isPlant: map['isPlant'] == true,
      cropGuess: str('cropGuess'),
      healthy: map['healthy'] == true,
      observed: str('observed'),
      problem: str('problem'),
      confidencePercent: _percent(map['confidencePercent'], map['confidence']),
      reason: str('reason'),
      alternatives: strList('alternatives').take(2).toList(),
      // An older server called this "deficiency".
      cause: str('cause').isNotEmpty ? str('cause') : str('deficiency'),
      treatment: strList('treatment'),
      prevention: strList('prevention'),
      needMore: str('needMore'),
      summary: str('summary'),
    );
  }

  /// The confidence as a whole number from 0 to 100. Falls back to an older
  /// server's low / medium / high [word].
  static int _percent(dynamic value, dynamic word) {
    final number = value is num ? value : num.tryParse('${value ?? ''}');
    if (number != null && number.isFinite) {
      return number.round().clamp(0, 100);
    }
    return switch ('$word') { 'high' => 85, 'medium' => 65, 'low' => 40, _ => 0 };
  }
}
