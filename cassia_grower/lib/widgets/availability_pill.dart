import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// The small status pill under a variety's name: green "Available", or
/// orange "Not available yet".
///
/// It goes with the big "Not available yet" stamp on the photo, never in
/// place of it.
class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({
    super.key,
    required this.available,
    this.large = false,
  });

  final bool available;

  /// The larger size, used on the product sheet.
  final bool large;

  static const _orange = Color(0xFFE8741A);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ink = available ? context.colors.green : _orange;
    final fill = (available ? AppColors.greenLight : _orange)
        .withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        available ? s.available : s.notAvailableYet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: large ? 12 : 10,
        ),
      ),
    );
  }
}
