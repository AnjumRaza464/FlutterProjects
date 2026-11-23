import 'package:material_ui/material_ui.dart';

import '../data/product_repository.dart';
import '../models/dealer_account.dart';
import '../models/farmer_profile.dart';
import '../models/product.dart';
import '../theme/app_palette.dart';
import 'admin_order.dart';
import 'dealer_admin_service.dart';
import 'farmer_admin_service.dart';
import 'order_admin_service.dart';

/// The admin "home" — a live overview of the business at a glance: key numbers,
/// the newest orders, and dealer applications waiting for review.
///
/// [onOpenSection] switches the shell's tab (1 Products · 2 Orders · 3 Farmers
/// · 4 Dealers) from the quick links here.
class OverviewView extends StatefulWidget {
  const OverviewView({super.key, required this.onOpenSection});

  final void Function(int index) onOpenSection;

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  // Streams are held so rebuilds (e.g. window resize) don't restart them.
  final _products = ProductRepository().watchProducts();
  final _orders = OrderAdminService().watchOrders();
  final _farmers = FarmerAdminService().watchFarmers();
  final _dealers = DealerAdminService().watchDealers();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
        children: [
          Text('Welcome back 👋',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 4),
          Text('Here is how Cassia Seed is doing right now.',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 22),
          _statsGrid(context),
          const SizedBox(height: 26),
          _twoColumns(
            context,
            left: _recentOrders(context),
            right: _pendingDealers(context),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- stats

  Widget _statsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width > 1040 ? 4 : (width > 640 ? 2 : 1);
        const gap = 16.0;
        final cardW = (width - gap * (cols - 1)) / cols;

        final cards = <Widget>[
          StreamBuilder<List<Product>>(
            stream: _products,
            builder: (context, snap) {
              final all = snap.data ?? const <Product>[];
              final available = all.where((p) => p.available).length;
              return _StatCard(
                icon: Icons.storefront_outlined,
                tint: const Color(0xFF2F7A3F),
                label: 'Products',
                value: snap.hasData ? '${all.length}' : '—',
                sub: '$available available',
                onTap: () => widget.onOpenSection(1),
              );
            },
          ),
          StreamBuilder<List<AdminOrder>>(
            stream: _orders,
            builder: (context, snap) {
              final all = snap.data ?? const <AdminOrder>[];
              final fresh =
                  all.where((o) => o.status == OrderStatus.placed).length;
              return _StatCard(
                icon: Icons.receipt_long_outlined,
                tint: const Color(0xFFC9A24B),
                label: 'New orders',
                value: snap.hasData ? '$fresh' : '—',
                sub: '${all.length} total',
                onTap: () => widget.onOpenSection(2),
              );
            },
          ),
          StreamBuilder<List<FarmerProfile>>(
            stream: _farmers,
            builder: (context, snap) {
              final all = snap.data ?? const <FarmerProfile>[];
              return _StatCard(
                icon: Icons.people_alt_outlined,
                tint: const Color(0xFF3A6EA5),
                label: 'Farmers',
                value: snap.hasData ? '${all.length}' : '—',
                sub: 'registered',
                onTap: () => widget.onOpenSection(3),
              );
            },
          ),
          StreamBuilder<List<DealerAccount>>(
            stream: _dealers,
            builder: (context, snap) {
              final all = snap.data ?? const <DealerAccount>[];
              final pending = all.where((d) => d.isPending).length;
              return _StatCard(
                icon: Icons.handshake_outlined,
                tint: const Color(0xFF8E5BB5),
                label: 'Dealers',
                value: snap.hasData ? '${all.length}' : '—',
                sub: pending == 0 ? 'all reviewed' : '$pending pending',
                onTap: () => widget.onOpenSection(4),
              );
            },
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: cardW, child: card)],
        );
      },
    );
  }

  // ------------------------------------------------------------- panels

  Widget _twoColumns(BuildContext context,
      {required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(children: [left, const SizedBox(height: 18), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 18),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }

  Widget _recentOrders(BuildContext context) {
    final c = context.colors;
    return _Panel(
      title: 'Recent orders',
      actionLabel: 'View all',
      onAction: () => widget.onOpenSection(2),
      child: StreamBuilder<List<AdminOrder>>(
        stream: _orders,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final orders = snap.data!.take(6).toList();
          if (orders.isEmpty) {
            return _empty('No orders yet.', c);
          }
          return Column(
            children: [
              for (final o in orders) _orderRow(context, o),
            ],
          );
        },
      ),
    );
  }

  Widget _orderRow(BuildContext context, AdminOrder o) {
    final c = context.colors;
    final (Color sc, String sl) = switch (o.status) {
      OrderStatus.placed => (c.gold, 'New'),
      OrderStatus.confirmed => (c.green, 'Confirmed'),
      OrderStatus.delivered => (c.muted, 'Delivered'),
      OrderStatus.cancelled => (c.danger, 'Cancelled'),
    };
    final name = o.order.customer.name.isNotEmpty
        ? o.order.customer.name
        : 'Unknown customer';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.green.withValues(alpha: 0.1),
            child: Icon(Icons.inventory_2_outlined, size: 18, color: c.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                Text(
                  '${o.order.ref.isNotEmpty ? '${o.order.ref} · ' : ''}'
                  '${o.order.totalQuantity} packs',
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _pill(sl, sc),
        ],
      ),
    );
  }

  Widget _pendingDealers(BuildContext context) {
    final c = context.colors;
    return _Panel(
      title: 'Dealer applications',
      actionLabel: 'Review',
      onAction: () => widget.onOpenSection(4),
      child: StreamBuilder<List<DealerAccount>>(
        stream: _dealers,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final pending = snap.data!.where((d) => d.isPending).take(5).toList();
          if (pending.isEmpty) {
            return _empty('No applications waiting. 🎉', c);
          }
          return Column(
            children: [
              for (final d in pending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: c.gold.withValues(alpha: 0.18),
                        child: Icon(Icons.store_outlined,
                            size: 18, color: c.goldInk),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d.businessName.isNotEmpty
                              ? d.businessName
                              : (d.ownerName.isNotEmpty
                                  ? d.ownerName
                                  : 'New applicant'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: c.ink),
                        ),
                      ),
                      _pill('Pending', c.gold),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(String text, AppPalette c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
            child: Text(text, style: TextStyle(color: c.muted))),
      );

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 11)),
      );
}

/// A KPI tile: coloured icon, a big number, a label and a one-line sub-stat.
class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _hover ? widget.tint.withValues(alpha: 0.5) : c.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.08 : 0.03),
                blurRadius: _hover ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.tint, size: 22),
              ),
              const SizedBox(height: 14),
              Text(widget.value,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      height: 1)),
              const SizedBox(height: 4),
              Text(widget.label,
                  style:
                      TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              Text(widget.sub,
                  style: TextStyle(color: c.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled white panel with an optional action link in its header.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: c.ink)),
              ),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}
