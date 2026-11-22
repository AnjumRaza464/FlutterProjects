import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../screens/cart_screen.dart';
import '../state/cart_scope.dart';
import '../theme/app_colors.dart';

/// A cart icon that opens the cart, with a badge showing how many packs are
/// in it.
class CartButton extends StatelessWidget {
  const CartButton({super.key, this.color});

  /// Icon colour; defaults to whatever the surrounding app bar uses.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final count = CartScope.of(context).totalQuantity;
    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
      ),
      tooltip: context.s.cart,
      color: color,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        // Fixed gold-on-brown: the badge sits on green in both themes.
        backgroundColor: AppColors.gold,
        textColor: AppColors.brown,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
