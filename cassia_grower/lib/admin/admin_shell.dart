import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dealer_account.dart';
import 'admin_order.dart';
import 'dashboard_screen.dart';
import 'dealer_admin_service.dart';
import 'dealers_screen.dart';
import 'farmers_screen.dart';
import 'order_admin_service.dart';
import 'orders_screen.dart';
import 'overview_screen.dart';

/// The admin panel shell: a persistent left sidebar + the selected section in
/// the content area. Replaces the old "app-bar buttons that push screens"
/// navigation with a single, cohesive dashboard.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // Streams for the sidebar badges (new orders, pending dealers).
  final _orders = OrderAdminService().watchOrders();
  final _dealers = DealerAdminService().watchDealers();

  // Built once so each section keeps its state (and live query) while you
  // switch tabs.
  late final List<Widget> _pages = [
    OverviewView(onOpenSection: _select),
    const DashboardScreen(),
    const OrdersScreen(),
    const FarmersScreen(),
    const DealersScreen(),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final expanded = MediaQuery.sizeOf(context).width >= 1080;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              index: _index,
              expanded: expanded,
              onSelect: _select,
              ordersStream: _orders,
              dealersStream: _dealers,
              onSignOut: () => FirebaseAuth.instance.signOut(),
            ),
            Expanded(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.index,
    required this.expanded,
    required this.onSelect,
    required this.ordersStream,
    required this.dealersStream,
    required this.onSignOut,
  });

  final int index;
  final bool expanded;
  final void Function(int index) onSelect;
  final Stream<List<AdminOrder>> ordersStream;
  final Stream<List<DealerAccount>> dealersStream;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 258 : 78,
      decoration: const BoxDecoration(
        // Fresh, lighter brand green (matches the website hero) instead of the
        // old dark forest green.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2EA863), Color(0xFF178F4E), Color(0xFF0F7A41)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 8),
          _item(0, Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
          _item(1, Icons.storefront_outlined, Icons.storefront, 'Products'),
          // Orders — badge of new/unhandled orders.
          StreamBuilder<List<AdminOrder>>(
            stream: ordersStream,
            builder: (context, snap) {
              final fresh = (snap.data ?? const <AdminOrder>[])
                  .where((o) => o.status == OrderStatus.placed)
                  .length;
              return _item(2, Icons.receipt_long_outlined,
                  Icons.receipt_long, 'Orders', badge: fresh);
            },
          ),
          _item(3, Icons.people_alt_outlined, Icons.people_alt, 'Farmers'),
          // Dealers — badge of applications awaiting review.
          StreamBuilder<List<DealerAccount>>(
            stream: dealersStream,
            builder: (context, snap) {
              final pending = (snap.data ?? const <DealerAccount>[])
                  .where((d) => d.isPending)
                  .length;
              return _item(4, Icons.handshake_outlined, Icons.handshake,
                  'Dealers', badge: pending);
            },
          ),
          const Spacer(),
          Divider(color: Colors.white.withValues(alpha: 0.20), height: 1),
          const SizedBox(height: 8),
          _SidebarButton(
            icon: Icons.logout,
            label: 'Sign out',
            expanded: expanded,
            onTap: onSignOut,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _header() {
    final logo = Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('🌱', style: TextStyle(fontSize: 22)),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(expanded ? 18 : 0, 20, 18, 16),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          logo,
          if (expanded) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cassia Seed',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text('Admin panel',
                      style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData activeIcon, String label,
      {int badge = 0}) {
    return _NavItem(
      icon: icon,
      activeIcon: activeIcon,
      label: label,
      selected: index == i,
      expanded: expanded,
      badge: badge,
      onTap: () => onSelect(i),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  static const _gold = Color(0xFFE2BD62);

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected ? Colors.white : Colors.white.withValues(alpha: 0.86);
    final bg = selected
        ? Colors.white.withValues(alpha: 0.20)
        : (_hover ? Colors.white.withValues(alpha: 0.12) : Colors.transparent);

    final row = Row(
      mainAxisAlignment: widget.expanded
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        _iconWithBadge(selected ? widget.activeIcon : widget.icon,
            selected ? _gold : fg),
        if (widget.expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Text(widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
          ),
        ],
      ],
    );

    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: EdgeInsets.symmetric(horizontal: widget.expanded ? 12 : 12),
          padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 14 : 0, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: row,
        ),
      ),
    );

    // Gold accent bar on the left of the active item.
    final withAccent = Stack(
      children: [
        tile,
        if (selected)
          PositionedDirectional(
            start: 0,
            top: 10,
            bottom: 10,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );

    if (widget.expanded) return withAccent;
    return Tooltip(message: widget.label, child: withAccent);
  }

  Widget _iconWithBadge(IconData icon, Color color) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 22),
        if (widget.badge > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                widget.badge > 99 ? '99+' : '${widget.badge}',
                style: const TextStyle(
                    color: Color(0xFF3A2A06),
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 14 : 0, vertical: 12),
          decoration: BoxDecoration(
            color: _hover
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.expanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  color: Colors.white.withValues(alpha: 0.86), size: 22),
              if (widget.expanded) ...[
                const SizedBox(width: 12),
                Text(widget.label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
    if (widget.expanded) return tile;
    return Tooltip(message: widget.label, child: tile);
  }
}
