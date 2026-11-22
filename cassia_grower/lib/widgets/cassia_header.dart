import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../state/app_settings.dart';
import '../theme/app_colors.dart';
import 'cassia_ui.dart';

/// The header shown above every tab, as in the approved design. From the
/// start of the line: a back button (on every tab but Home), the logo over
/// the company's motto, then the profile button, the light/dark switch and
/// the language menu. White fading to cream, with rounded bottom corners
/// and a dashed gold line just under it.
///
/// Its colours are fixed: the header looks the same in light and dark mode.
class CassiaHeader extends StatelessWidget implements PreferredSizeWidget {
  const CassiaHeader({super.key, this.onBack, this.onProfile});

  /// Goes back to the tab the farmer came from. Null hides the button, as
  /// on Home, where there is nowhere to go back to.
  final VoidCallback? onBack;

  /// Opens the farmer's own page. Null hides the button.
  final VoidCallback? onProfile;

  static const _ink = AppColors.brown;

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.maybeOf(context);
    final s = context.s;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onProfile != null)
          _HeaderPill(
            tooltip: s.supportAndAbout,
            onTap: onProfile!,
            child: const Text('👤', style: TextStyle(fontSize: 13, height: 1.3)),
          ),
        if (settings != null) ...[
          const SizedBox(width: 6),
          _ThemeSwitch(
            dark: dark,
            tooltip: s.switchTheme,
            onTap: () =>
                settings.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 6),
          _LanguageMenu(settings: settings),
        ],
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFBF5E6)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1F4A2F1B), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  // With the back button showing, the logo sits midway
                  // between it and the buttons; without it, at the start.
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (onBack != null) ...[
                      _HeaderPill(
                        tooltip: s.back,
                        onTap: onBack!,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        // The arrow points back the way the language reads.
                        child: Text(
                          s.isUrdu ? '→' : '←',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // On a narrow phone the logo gives way, not the buttons.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: _brand(s),
                      ),
                    ),
                    const SizedBox(width: 8),
                    buttons,
                  ],
                ),
              ),
              // The dashed gold line hangs just below the header.
              const Positioned(
                left: 18,
                right: 18,
                bottom: -5,
                height: 4,
                child: CustomPaint(painter: _GoldDashes()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The logo with the motto in small gold capitals under it.
  Widget _brand(AppStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CassiaLogo(height: 44),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2),
          child: Text(
            // Urdu has no capitals, and is never letter-spaced.
            '${s.isUrdu ? s.motto : s.motto.toUpperCase()} 🌱',
            style: TextStyle(
              color: const Color(0xFFA37D2C),
              // Urdu script needs to be a little larger to be read.
              fontSize: s.isUrdu ? 11 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: s.spacing(2),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// A small cream button in the header, with a lip it presses down into.
class _HeaderPill extends StatefulWidget {
  const _HeaderPill({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.round = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final EdgeInsetsGeometry padding;

  /// A 42-pixel circle (the light/dark switch) instead of a pill.
  final bool round;

  @override
  State<_HeaderPill> createState() => _HeaderPillState();
}

class _HeaderPillState extends State<_HeaderPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
            width: widget.round ? 42 : null,
            height: widget.round ? 42 : null,
            padding: widget.round ? EdgeInsets.zero : widget.padding,
            alignment: widget.round ? Alignment.center : null,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE3),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFE6DCC5)),
              boxShadow: [
                if (!_down)
                  const BoxShadow(
                      color: Color(0xFFD9CCB0), offset: Offset(0, 3)),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The light/dark switch: a disc that is half sun-yellow and half night,
/// and swings round when the theme changes.
class _ThemeSwitch extends StatelessWidget {
  const _ThemeSwitch({
    required this.dark,
    required this.onTap,
    required this.tooltip,
  });

  final bool dark;
  final VoidCallback onTap;
  final String tooltip;

  static const _sun = Color(0xFFF6C945);
  static const _night = Color(0xFF15151A);

  @override
  Widget build(BuildContext context) {
    return _HeaderPill(
      tooltip: tooltip,
      onTap: onTap,
      round: true,
      child: AnimatedRotation(
        turns: dark ? 0.5 : 0,
        duration: const Duration(milliseconds: 800),
        // Overshoots a little before settling, as in the design.
        curve: const Cubic(0.3, 1.5, 0.5, 1),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_sun, _sun, _night, _night],
              stops: [0, 0.5, 0.5, 1],
            ),
            // A white ring inside a thin cream one; in dark mode, a glow.
            boxShadow: [
              if (dark) const BoxShadow(color: Color(0x88F6C945), blurRadius: 12),
              const BoxShadow(color: Color(0xFFD9CCB0), spreadRadius: 3),
              const BoxShadow(color: Colors.white, spreadRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// The language button: shows the language the app is in ("🌐 EN") and
/// opens a short menu of the languages to choose from.
class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.settings});

  final AppSettings settings;

  // Each language is named in itself, whatever language the app is in.
  static String _short(AppLanguage language) => switch (language) {
        AppLanguage.en => 'EN',
        AppLanguage.ur => 'اردو',
      };

  static String _name(AppLanguage language) => switch (language) {
        AppLanguage.en => 'English',
        AppLanguage.ur => 'اردو',
      };

  Future<void> _open(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final at = button.localToGlobal(Offset.zero, ancestor: overlay);
    // Just under the button, lined up with its outer edge.
    final below = Rect.fromLTWH(at.dx, at.dy + button.size.height + 10,
        button.size.width, 0);
    final current = settings.language;

    final chosen = await showMenu<AppLanguage>(
      context: context,
      position: RelativeRect.fromRect(below, Offset.zero & overlay.size),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      menuPadding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 130),
      items: [
        for (final language in AppLanguage.values)
          PopupMenuItem(
            value: language,
            height: 40,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: language == current ? const Color(0xFFEAF3E4) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _name(language),
                style: TextStyle(
                  color: language == current
                      ? AppColors.green
                      : const Color(0xFF2B1D10),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
    if (chosen != null) settings.setLanguage(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return _HeaderPill(
      tooltip: context.s.changeLanguage,
      onTap: () => _open(context),
      child: Text(
        '🌐 ${_short(settings.language)}',
        style: const TextStyle(
          color: CassiaHeader._ink,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0,
          height: 1.3,
        ),
      ),
    );
  }
}

/// The dashed gold line under the header.
class _GoldDashes extends CustomPainter {
  const _GoldDashes();

  static const double _dash = 14;
  static const double _gap = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 0.55);
    final all = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(size.height));
    canvas.save();
    canvas.clipRRect(all); // rounded ends, as one bar
    for (var x = 0.0; x < size.width; x += _dash + _gap) {
      canvas.drawRect(Rect.fromLTWH(x, 0, _dash, size.height), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoldDashes old) => false;
}
