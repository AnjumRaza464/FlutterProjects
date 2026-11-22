import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Building blocks of the app's look, taken from the approved design: the
/// logo, "raised" cards and buttons with a solid lip underneath, and section
/// titles with a gold bar. (The header itself is in cassia_header.dart.)

/// The decoration of a raised card: a solid lip under a soft shadow.
BoxDecoration raisedBox(BuildContext context, {double radius = 20}) {
  final c = context.colors;
  return BoxDecoration(
    color: c.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: c.line),
    boxShadow: [
      BoxShadow(color: c.line, offset: const Offset(0, 5)),
      const BoxShadow(
          color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 12)),
    ],
  );
}

/// The Cassia Seed logo. The artwork has a white background, so it always
/// sits on a white chip — in dark mode too.
class CassiaLogo extends StatelessWidget {
  const CassiaLogo({super.key, this.height = 46});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        'assets/brand/logo.png',
        height: height,
        fit: BoxFit.contain,
        // Where the artwork can't load, the name stands in for it.
        errorBuilder: (context, error, stack) => SizedBox(
          height: height,
          child: const Center(
            child: Text(
              'Cassia Seed',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A section heading with the design's gold bar, and optionally a link on
/// the far side ("See all").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: c.gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
            ),
          ),
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  action!,
                  style: TextStyle(
                      color: c.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The design's chunky button: a solid lip underneath that it presses into.
class PressButton extends StatefulWidget {
  const PressButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gold = true,
    this.icon,
    this.dense = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Gold with dark text (the default), or green with white text.
  final bool gold;
  final IconData? icon;

  /// A smaller pill, for use inside a banner.
  final bool dense;

  @override
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    // Fixed colours: these buttons sit on coloured banners in both themes.
    final face = widget.gold ? AppColors.gold : AppColors.greenLight;
    final lip = widget.gold ? const Color(0xFF8A6D1F) : const Color(0xFF17492A);
    final ink = widget.gold ? AppColors.ink : Colors.white;
    final lift = _down ? 1.0 : (widget.dense ? 4.0 : 5.0);

    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.dense ? 16 : 18,
            vertical: widget.dense ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(widget.dense ? 99 : 14),
            boxShadow: [
              BoxShadow(color: lip, offset: Offset(0, lift)),
              if (!_down)
                const BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 16,
                    offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: ink),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: widget.dense ? 13 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The design's full-width button: green with a dark lip it presses into,
/// or — [outlined] — card-coloured with a pale lip. With no [onTap] it is
/// switched off: faded and flat.
class BlockButton extends StatefulWidget {
  const BlockButton({
    super.key,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  State<BlockButton> createState() => _BlockButtonState();
}

class _BlockButtonState extends State<BlockButton> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onTap != null) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = widget.onTap != null;
    final outlined = widget.outlined;
    // The green is the same in both themes, as in the design.
    final face = outlined ? c.card : AppColors.greenLight;
    final lip = outlined ? c.line : const Color(0xFF17492A);
    final ink = outlined ? c.ink : Colors.white;
    final down = _down && enabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapCancel: () => _press(false),
        onTapUp: (_) => _press(false),
        onTap: widget.onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            transform: Matrix4.translationValues(0, down ? 4 : 0, 0),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(14),
              border: outlined ? Border.all(color: c.line) : null,
              boxShadow: [
                if (enabled) BoxShadow(color: lip, offset: Offset(0, down ? 1 : 5)),
                if (enabled && !down)
                  BoxShadow(
                    color: outlined
                        ? const Color(0x22000000)
                        : const Color(0x33000000),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lets a sideways strip — a gallery, a row of chips — be dragged with a
/// mouse as well as a finger, so it also works in a desktop browser.
class DragScroll extends StatelessWidget {
  const DragScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: child,
    );
  }
}

// The toast on screen, if any: a new one takes its place.
OverlayEntry? _toastOnScreen;

/// Shows the design's toast: a short message in a dark pill that floats
/// above the bottom bar for a moment. It sits over everything, sheets
/// included, and never takes a tap.
void showToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastOnScreen?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Toast(
      message: message,
      onDone: () {
        if (_toastOnScreen == entry) _toastOnScreen = null;
        entry.remove();
      },
    ),
  );
  _toastOnScreen = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  // Slides up and fades in, stays, then fades out. This is how long the
  // message can be read for, so it is not cut short on a phone that asks
  // for reduced animations.
  late final _life = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
      animationBehavior: AnimationBehavior.preserve)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1), weight: 78),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 12),
  ]).animate(_life);

  late final _rise = Tween(begin: const Offset(0, 0.6), end: Offset.zero)
      .animate(CurvedAnimation(
          parent: _life, curve: const Interval(0, 0.1, curve: Curves.easeOut)));

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 104 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _rise,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screen.width * 0.9),
                child: Material(
                  color: AppColors.ink,
                  shape: const StadiumBorder(),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A burst of seedlings and sparkles from the bottom of the screen, as the
/// design shows when something is added to the order.
void showSeedBurst(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || MediaQuery.disableAnimationsOf(context)) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _SeedBurst(onDone: entry.remove));
  overlay.insert(entry);
}

class _SeedBurst extends StatefulWidget {
  const _SeedBurst({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_SeedBurst> createState() => _SeedBurstState();
}

class _SeedBurstState extends State<_SeedBurst>
    with SingleTickerProviderStateMixin {
  static const _pieces = ['🌱', '🌿', '✨', '🍅', '🌶️', '🌾'];
  static const _count = 22;

  late final _flight = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  // Where each piece lands, and how far it spins on the way.
  late final List<(Offset, double)> _paths = () {
    final random = math.Random();
    return [
      for (var i = 0; i < _count; i++)
        (
          Offset(random.nextDouble() * 320 - 160,
              -(120 + random.nextDouble() * 260)),
          (random.nextDouble() * 3 - 1.5) * math.pi,
        ),
    ];
  }();

  @override
  void dispose() {
    _flight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = MediaQuery.sizeOf(context).bottomCenter(Offset.zero) -
        Offset(0, 110 + MediaQuery.paddingOf(context).bottom);
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _flight,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_flight.value);
              return Stack(
                children: [
                  for (var i = 0; i < _count; i++)
                    Positioned(
                      left: start.dx + _paths[i].$1.dx * t - 11,
                      top: start.dy + _paths[i].$1.dy * t - 11,
                      child: Opacity(
                        opacity: 1 - t,
                        child: Transform.rotate(
                          angle: _paths[i].$2 * t,
                          child: Text(
                            _pieces[i % _pieces.length],
                            style: const TextStyle(
                              fontSize: 22,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A big page title with an optional line of help under it, used at the top
/// of a tab (the header above it carries the logo, not the page name).
class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(color: c.muted, fontSize: 14)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
