import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../state/cart_controller.dart';
import '../state/cart_scope.dart';
import '../theme/app_palette.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/removed_notice.dart';
import 'checkout_screen.dart';

/// The cart: every variety the farmer has picked, with its quantity.
///
/// There are no prices here — Cassia Seed confirms them on WhatsApp once the
/// order is sent. Only available varieties can ever be listed: the cart drops
/// a line as soon as its variety stops being available (see [RemovedNotice]).
class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    this.orderService,
    this.embedded = false,
    this.onBrowse,
  });

  /// Passed on to checkout. Replaceable in tests.
  final OrderService? orderService;

  /// True when shown as the "Order" tab under the app's shared header: the
  /// screen then has no bar of its own and shows a page title instead.
  final bool embedded;

  /// As a tab, what the empty cart's button does (opens the Shop). Without
  /// it, the button goes back.
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(context.s.yourCart)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (embedded) PageTitle('\u{1F6D2} ${context.s.myOrder}'),
          const RemovedNotice(),
          Expanded(
            child: cart.isEmpty ? _empty(context) : _lines(context, cart),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty ? null : _continueBar(context, cart),
    );
  }

  Widget _empty(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 64, color: c.green.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(s.cartEmpty,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
            const SizedBox(height: 6),
            Text(
              s.cartEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
            const SizedBox(height: 22),
            if (onBrowse != null)
              FilledButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.storefront_outlined),
                label: Text(s.seedShop),
              )
            else
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(s.back),
              ),
          ],
        ),
      ),
    );
  }

  Widget _lines(BuildContext context, CartController cart) {
    final items = cart.items;
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _line(context, cart, items[i]),
    );
  }

  Widget _line(BuildContext context, CartController cart, CartItem item) {
    final c = context.colors;
    final details = [
      if (item.crop.isNotEmpty) item.crop,
      if (item.packSize.isNotEmpty) item.packSize,
    ].join(' • ');

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          // The pack, so the farmer recognises each line at a glance.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 50,
              height: 60,
              child: ProductImage(
                padding: const EdgeInsets.all(3),
                product: Product(
                  id: item.productId,
                  name: item.name,
                  crop: item.crop,
                  cropKey: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style:
                        TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(context.s.data(details),
                      style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          QuantityStepper(
            quantity: item.quantity,
            onChanged: (q) => cart.setQuantity(item.productId, q),
          ),
        ],
      ),
    );
  }

  Widget _continueBar(BuildContext context, CartController cart) {
    final c = context.colors;
    final s = context.s;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.cartSummary(cart.items.length, cart.totalQuantity),
                style: TextStyle(fontWeight: FontWeight.w800, color: c.ink),
              ),
              const SizedBox(height: 2),
              Text(
                s.priceConfirmedOnWhatsApp,
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(orderService: orderService),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: Text(s.continueLabel),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
