import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// A large, attractive "Not available yet" label shown on top of a product
/// image for varieties that are not yet available to order (e.g. unregistered
/// varieties). It replaces the old small "out of stock" text so the item
/// never looks like it is on sale.
///
/// Its gold-and-brown colours are fixed on purpose: the stamp sits on a photo
/// and must read the same in light and dark mode.
class NotAvailableBadge extends StatelessWidget {
  const NotAvailableBadge({super.key, this.compact = false});

  /// Smaller version used on product cards; larger on the detail screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double hPad = compact ? 12 : 20;
    final double vPad = compact ? 7 : 12;
    final double fontSize = compact ? 12 : 17;

    return Container(
      // Dim the image slightly so the badge reads clearly.
      color: Colors.black.withValues(alpha: 0.28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // Shrinks the stamp to fit a narrow card or a longer translation,
      // rather than letting it spill over the edges.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.rotate(
          angle: -0.08, // a slight tilt looks more like a stamp
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: Colors.white,
                width: compact ? 1.5 : 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: AppColors.brown,
                  size: compact ? 14 : 20,
                ),
                SizedBox(width: compact ? 5 : 8),
                Text(
                  context.s.notAvailableYet,
                  style: TextStyle(
                    color: AppColors.brown,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    letterSpacing: context.s.spacing(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
