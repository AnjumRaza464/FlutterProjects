import 'package:material_ui/material_ui.dart';

import '../widgets/cassia_ui.dart';
import 'root_nav.dart';

/// Shown the moment the app opens: the Cassia brand screen (logo + a gold
/// loading bar that sweeps across) holds for a beat, then cross-fades into the
/// main app. Matches the splash in the approved HTML prototype.
///
/// Tests and other entry points can skip this by passing their own `home`
/// to `CassiaApp`; this gate is only the default first screen.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  /// How long the brand screen stays before the app is revealed. Lines up with
  /// the loading-bar sweep (1.3s) plus a short pause, like the prototype.
  static const _hold = Duration(milliseconds: 6000);

  /// Length of the cross-fade from splash to app.
  static const _fade = Duration(milliseconds: 600);

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_hold, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: _fade,
      child: _ready
          ? const RootNav(key: ValueKey('app'))
          : const _CassiaSplash(key: ValueKey('splash')),
    );
  }
}

/// The brand screen itself: a fresh green gradient, the logo on its white chip,
/// the "GROW WITH CASSIA" line, and a gold bar that sweeps in from the left.
class _CassiaSplash extends StatefulWidget {
  const _CassiaSplash({super.key});

  @override
  State<_CassiaSplash> createState() => _CassiaSplashState();
}

class _CassiaSplashState extends State<_CassiaSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fresh brand green — matches the admin panel's sign-in background.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2EA863), Color(0xFF178F4E), Color(0xFF0F7A41)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CassiaLogo(height: 84),
            const SizedBox(height: 22),
            Text(
              'GROW WITH CASSIA',
              style: TextStyle(
                color: const Color(0xFFF1D98F),
                fontSize: 13,
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _LoadingBar(progress: _sweep),
          ],
        ),
      ),
    );
  }
}

/// A 150×5 rounded track with a gold fill that slides in from the left,
/// mirroring the prototype's `translateX(-100% → 0)` sweep.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    const width = 150.0;
    const height = 5.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // The track.
            Container(color: Colors.white.withValues(alpha: 0.19)),
            // The gold fill, swept in from fully off the left edge.
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) => Transform.translate(
                offset: Offset(-width * (1 - progress.value), 0),
                child: Container(
                  width: width,
                  height: height,
                  color: const Color(0xFFF1D98F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
