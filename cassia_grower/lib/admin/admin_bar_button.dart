import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// A labelled action in the admin app bar: an icon with its name beside it
/// (e.g. 🤝 Dealers), a hover highlight, an optional count badge, and a
/// tooltip. On a narrow window the label is dropped so the bar never
/// overflows — just the icon shows, with the name still in its tooltip.
class AdminBarButton extends StatefulWidget {
  const AdminBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// A number shown in a small gold badge on the icon; 0 hides it.
  final int badgeCount;

  /// Below this width the label is hidden and only the icon shows.
  static const double _labelBreakpoint = 700;

  @override
  State<AdminBarButton> createState() => _AdminBarButtonState();
}

class _AdminBarButtonState extends State<AdminBarButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final showLabel =
        MediaQuery.sizeOf(context).width >= AdminBarButton._labelBreakpoint;

    final icon = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(widget.icon, color: Colors.white, size: 22),
        if (widget.badgeCount > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                style: const TextStyle(
                    color: AppColors.brown,
                    fontSize: 10,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );

    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
            padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 12 : 10, vertical: 8),
            decoration: BoxDecoration(
              color: _hover
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
