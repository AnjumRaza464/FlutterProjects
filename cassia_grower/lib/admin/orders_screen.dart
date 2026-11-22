import 'package:material_ui/material_ui.dart';

import '../services/launchers.dart';
import '../theme/app_colors.dart';
import 'admin_bar_button.dart';
import 'admin_order.dart';
import 'order_admin_service.dart';

/// Admin view of the orders farmers send from the app: who ordered what, with
/// a status to track each one and quick ways to reply to the customer.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.service});

  /// Replaceable in tests; defaults to the real Firestore service.
  final OrderAdminService? service;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrderAdminService _service =
      widget.service ?? OrderAdminService();
  // Held here so rebuilding the screen doesn't restart the live query.
  late final Stream<List<AdminOrder>> _orders = _service.watchOrders();

  /// The status being shown; null shows every order.
  OrderStatus? _filter;

  Future<void> _setStatus(AdminOrder order, OrderStatus status) async {
    try {
      await _service.setStatus(order.id, status);
    } catch (e) {
      _say('Could not update the order: $e');
    }
  }

  Future<void> _confirmDelete(AdminOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete order?'),
        content: Text('Order ${order.order.ref} from '
            '${order.order.customer.name} will be permanently removed. This '
            'cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(order.id);
      _say('Deleted order ${order.order.ref}.');
    } catch (e) {
      _say('Could not delete the order: $e');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AdminOrder>>(
        stream: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Could not load orders.\n\n'
              'Check that the Firestore rules let signed-in admins read the '
              '"orders" collection (see ADMIN.md).\n\n${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final shown = _filter == null
              ? all
              : all.where((o) => o.status == _filter).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  _filterBar(all),
                  Expanded(
                    child: shown.isEmpty
                        ? _message(_filter == null
                            ? 'No orders yet. Orders farmers send from the '
                                'app will appear here.'
                            : 'No ${_filter!.label.toLowerCase()} orders.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: shown.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _card(shown[i]),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4)),
      ),
    );
  }

  Widget _filterBar(List<AdminOrder> all) {
    int count(OrderStatus s) => all.where((o) => o.status == s).length;
    // A Wrap rather than a sideways-scrolling row: on a narrow window the
    // chips drop to a second line instead of hiding off the edge.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterChip('All (${all.length})', null),
          for (final s in OrderStatus.values)
            _filterChip('${s.label} (${count(s)})', s),
        ],
      ),
    );
  }

  Widget _filterChip(String label, OrderStatus? status) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == status,
      onSelected: (_) => setState(() => _filter = status),
    );
  }

  Widget _card(AdminOrder o) {
    final customer = o.order.customer;
    final packs = o.order.totalQuantity;
    final whatsApp = o.whatsAppNumber;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.order.ref.isNotEmpty ? o.order.ref : '(no number)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink),
                      ),
                      Text(_when(o.createdAt),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                _statusMenu(o),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              [
                if (customer.name.isNotEmpty) customer.name,
                if (customer.city.isNotEmpty) customer.city,
              ].join(' • '),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            if (customer.phone.isNotEmpty)
              SelectableText(customer.phone,
                  style: const TextStyle(color: AppColors.ink)),
            const Divider(height: 22, color: AppColors.line),
            for (final item in o.order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        [
                          item.packSize.isNotEmpty
                              ? '${item.name} (${item.packSize})'
                              : item.name,
                          if (item.crop.isNotEmpty) item.crop,
                        ].join(', '),
                        style: const TextStyle(color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('× ${item.quantity}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              ),
            if (o.order.items.isEmpty)
              const Text('(no items)',
                  style: TextStyle(color: AppColors.muted)),
            if (customer.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${customer.note}',
                  style: const TextStyle(
                      color: AppColors.muted, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text('$packs ${packs == 1 ? 'pack' : 'packs'}',
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12)),
                const Spacer(),
                if (whatsApp.isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        Launchers.openWebsite('https://wa.me/$whatsApp'),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.green),
                  ),
                if (customer.phone.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => Launchers.dialPhone(customer.phone),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.green),
                  ),
                IconButton(
                  tooltip: 'Delete order',
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                  onPressed: () => _confirmDelete(o),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The order's status as a coloured pill; tapping it offers the others.
  Widget _statusMenu(AdminOrder o) {
    final color = switch (o.status) {
      OrderStatus.placed => AppColors.brown,
      OrderStatus.confirmed => AppColors.green,
      OrderStatus.delivered => AppColors.muted,
      OrderStatus.cancelled => Colors.red.shade700,
    };
    return PopupMenuButton<OrderStatus>(
      tooltip: 'Change status',
      onSelected: (status) => _setStatus(o, status),
      itemBuilder: (_) => [
        for (final s in OrderStatus.values)
          if (s != o.status)
            PopupMenuItem(value: s, child: Text('Mark as ${s.label}')),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(o.status.label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            Icon(Icons.arrow_drop_down, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "21 Nov 2026, 6:45 PM" in the admin's own time zone.
  static String _when(DateTime? at) {
    if (at == null) return 'Time not recorded';
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final half = at.hour < 12 ? 'AM' : 'PM';
    return '${at.day} ${_months[at.month - 1]} ${at.year}, $hour:$minute $half';
  }
}

/// App-bar button that opens [OrdersScreen], with a badge counting the orders
/// nobody has handled yet.
class OrdersButton extends StatefulWidget {
  const OrdersButton({super.key, this.service});

  final OrderAdminService? service;

  @override
  State<OrdersButton> createState() => _OrdersButtonState();
}

class _OrdersButtonState extends State<OrdersButton> {
  late final OrderAdminService _service =
      widget.service ?? OrderAdminService();
  late final Stream<List<AdminOrder>> _orders = _service.watchOrders();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        // If orders can't be read the button still works; the orders screen
        // explains what is wrong.
        final fresh = (snapshot.data ?? const <AdminOrder>[])
            .where((o) => o.status == OrderStatus.placed)
            .length;
        return AdminBarButton(
          icon: Icons.receipt_long_outlined,
          label: 'Orders',
          badgeCount: fresh,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OrdersScreen(service: _service),
          )),
        );
      },
    );
  }
}
