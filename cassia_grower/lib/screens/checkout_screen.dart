import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../models/cart_item.dart';
import '../models/seed_order.dart';
import '../services/order_service.dart';
import '../state/cart_scope.dart';
import '../theme/app_palette.dart';
import '../widgets/removed_notice.dart';
import 'order_sent_screen.dart';

/// The last step of ordering: the farmer's contact details, a summary of the
/// cart, and "Send order on WhatsApp".
///
/// Sending saves the order to Firestore (for the admin panel) and opens
/// WhatsApp with the order written out, ready for the farmer to send. The
/// contact details are remembered on the phone for the next order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.orderService});

  /// Replaceable in tests; defaults to the real Firestore + WhatsApp service.
  final OrderService? orderService;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final OrderService _service = widget.orderService ?? OrderService();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _note = TextEditingController();

  // One order number for this visit, so trying again after a failure doesn't
  // look like a second order.
  final String _ref = SeedOrder.newRef();

  bool _sending = false;
  bool _failed = false;
  List<CartItem>? _sentItems;

  AppPalette get _c => context.colors;
  AppStrings get _s => context.s;

  @override
  void initState() {
    super.initState();
    final last = CartScope.read(context).customer;
    _name.text = last.name;
    _phone.text = last.phone;
    _city.text = last.city;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final cart = CartScope.read(context);
    if (_sending || cart.isEmpty) return;
    if (!_form.currentState!.validate()) return;

    final customer = CustomerDetails(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
      note: _note.text.trim(),
    );
    // The note is about this order only, so it isn't remembered.
    cart.rememberCustomer(CustomerDetails(
      name: customer.name,
      phone: customer.phone,
      city: customer.city,
    ));
    final order = SeedOrder(ref: _ref, customer: customer, items: cart.items);

    setState(() {
      _sending = true;
      _failed = false;
    });
    final saved = await _service.save(order);
    final opened = await _service.openWhatsApp(order);
    if (!mounted) return;

    // The order counts as sent if it reached Cassia Seed either way: WhatsApp
    // is open with it, or it is confirmed saved for the team to pick up.
    if (!opened && saved != SaveOutcome.saved) {
      setState(() {
        _sending = false;
        _failed = true;
      });
      return;
    }

    // Keep showing what was ordered while this page slides away, rather than
    // flashing the emptied cart.
    _sentItems = order.items;
    cart.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderSentScreen(
          order: order,
          whatsAppOpened: opened,
          orderService: _service,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _sentItems ?? CartScope.of(context).items;
    return Scaffold(
      appBar: AppBar(title: Text(_s.yourDetails)),
      body: Column(
        children: [
          const RemovedNotice(),
          Expanded(child: items.isEmpty ? _nothingLeft() : _formView(items)),
        ],
      ),
    );
  }

  /// Shown if every variety was withdrawn while the farmer was on this page.
  Widget _nothingLeft() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: _c.muted),
            const SizedBox(height: 12),
            Text(_s.nothingLeftToOrder,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17, color: _c.ink)),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_s.backToCart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formView(List<CartItem> items) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field(
            controller: _name,
            label: _s.yourName,
            icon: Icons.person_outline,
            capitalization: TextCapitalization.words,
            validator: (v) => v.isEmpty ? _s.enterName : null,
          ),
          _field(
            controller: _phone,
            label: _s.phoneNumber,
            icon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
            // A phone number is typed left to right in either language.
            textDirection: TextDirection.ltr,
            validator: (v) =>
                CustomerDetails.isValidPhone(v) ? null : _s.enterValidPhone,
          ),
          _field(
            controller: _city,
            label: _s.cityOrVillage,
            icon: Icons.location_on_outlined,
            capitalization: TextCapitalization.words,
            validator: (v) => v.isEmpty ? _s.enterCity : null,
          ),
          _field(
            controller: _note,
            label: _s.noteOptional,
            icon: Icons.notes_outlined,
            maxLines: 3,
            maxLength: 300,
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 6),
          _summary(items),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 15, color: _c.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _s.checkoutInfo,
                  style:
                      TextStyle(color: _c.muted, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
          if (_failed) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _c.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _c.danger.withValues(alpha: 0.5)),
              ),
              child: Text(_s.orderNotSent(AppConfig.phone),
                  style: TextStyle(color: _c.danger, height: 1.4)),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.chat),
            label: Text(_sending ? _s.sending : _s.sendOrderOnWhatsApp),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    TextDirection? textDirection,
    int maxLines = 1,
    int? maxLength,
    String? Function(String value)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        textDirection: textDirection,
        maxLines: maxLines,
        maxLength: maxLength,
        validator:
            validator == null ? null : (v) => validator((v ?? '').trim()),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _c.green),
          filled: true,
          fillColor: _c.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _summary(List<CartItem> items) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_s.yourOrder,
              style: TextStyle(fontWeight: FontWeight.w800, color: _c.ink)),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.packSize.isNotEmpty
                          ? '${item.name} (${item.packSize})'
                          : item.name,
                      style: TextStyle(color: _c.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('× ${item.quantity}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: _c.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
