import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../models/seed_order.dart';
import '../services/order_service.dart';
import '../theme/app_palette.dart';

/// Shown after checkout. It says honestly where the order stands: WhatsApp
/// only opens a draft, so the farmer still has to press send there.
class OrderSentScreen extends StatelessWidget {
  const OrderSentScreen({
    super.key,
    required this.order,
    required this.whatsAppOpened,
    this.orderService,
  });

  final SeedOrder order;

  /// False when WhatsApp couldn't be opened; the order was then saved for
  /// Cassia Seed's team instead.
  final bool whatsAppOpened;

  final OrderService? orderService;

  Future<void> _openWhatsApp(BuildContext context) async {
    final opened =
        await (orderService ?? OrderService()).openWhatsApp(order);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.couldNotOpenWhatsApp)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.order),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  whatsAppOpened ? Icons.chat : Icons.check_circle_outline,
                  size: 56,
                  color: c.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                whatsAppOpened ? s.pressSendInWhatsApp : s.orderReceived,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: c.ink),
              ),
              const SizedBox(height: 8),
              Text(
                whatsAppOpened
                    ? s.whatsAppOpenedBody
                    : s.orderReceivedBody(
                        order.customer.phone, AppConfig.phone),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.line),
                ),
                child: Text(
                  s.orderNo(order.ref),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _openWhatsApp(context),
                icon: const Icon(Icons.chat),
                label: Text(
                    whatsAppOpened ? s.openWhatsAppAgain : s.tryWhatsAppAgain),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: Text(s.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
