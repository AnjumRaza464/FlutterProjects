import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/cart_scope.dart';
import '../theme/app_palette.dart';

/// Tells the farmer when varieties were taken out of their cart because they
/// are no longer available. Shows nothing when there is nothing to report.
class RemovedNotice extends StatelessWidget {
  const RemovedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final cart = CartScope.of(context);
    final names = cart.removedNotice;
    if (names.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.18),
        border: Border(bottom: BorderSide(color: c.gold)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.schedule, size: 18, color: c.goldInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.removedFromCart(names.join(', ')),
              style: TextStyle(color: c.goldInk, height: 1.35),
            ),
          ),
          IconButton(
            onPressed: cart.dismissRemovedNotice,
            icon: const Icon(Icons.close, size: 18),
            tooltip: s.dismiss,
            color: c.goldInk,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
