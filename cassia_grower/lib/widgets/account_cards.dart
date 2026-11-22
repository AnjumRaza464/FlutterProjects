import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../screens/account/dealer_portal_screen.dart';
import '../screens/account/farmer_auth_screen.dart';
import '../services/account_service.dart';

/// The two cards at the top of Home, as in the v5 design: a dark "Dealership"
/// card and a green "Farmer Login" card. Each one's wording follows who is
/// signed in — "Farmer Login" becomes "My Farmer Account", "Dealership"
/// becomes "View your dashboard".
class AccountTopCards extends StatelessWidget {
  const AccountTopCards({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final role = CassiaAccounts.roleOf(snapshot.data);
        final isDealer = role == AccountRole.dealer;
        final isFarmer = role == AccountRole.farmer;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          // IntrinsicHeight bounds the Row's height so the two cards can
          // stretch to match each other inside the (unbounded) ListView.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: _AccountCard(
                  icon: '🤝',
                  kicker: s.forDealers,
                  title: isDealer ? s.viewDashboard : s.dealership,
                  subtitle: s.dealershipSub,
                  gradient: const [Color(0xFF2B2318), Color(0xFF3C3220)],
                  arrowBg: const Color(0x33FFFFFF),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DealerPortalScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccountCard(
                  icon: '🧑‍🌾',
                  kicker: s.forFarmers,
                  title: isFarmer ? s.myFarmerAccount : s.farmerLogin,
                  subtitle: s.farmerLoginSub,
                  gradient: const [Color(0xFF1F5A30), Color(0xFF2F7A3F)],
                  arrowBg: const Color(0x33FFFFFF),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const FarmerAuthScreen()),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountCard extends StatefulWidget {
  const _AccountCard({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.arrowBg,
    required this.onTap,
  });

  final String icon;
  final String kicker;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color arrowBg;
  final VoidCallback onTap;

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard>
    with SingleTickerProviderStateMixin {
  bool _down = false;

  // A soft light streak that sweeps diagonally across the card, then rests.
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  /// The moving highlight. The bright band crosses in the first third of the
  /// cycle, then the card rests until the next sweep.
  Widget _buildShine() {
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, _) {
        final sweep = (_shine.value / 0.3).clamp(0.0, 1.0);
        final x = -0.25 + sweep * 1.5;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x2BFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: [
                (x - 0.16).clamp(0.0, 1.0),
                x.clamp(0.0, 1.0),
                (x + 0.16).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Semantics(
      button: true,
      label: '${widget.kicker} ${widget.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
          constraints: const BoxConstraints(minHeight: 132),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!_down)
                const BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8)),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                  child: IgnorePointer(child: _buildShine())),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 10),
              Text(
                widget.kicker,
                style: TextStyle(
                  color: const Color(0xFFE2BD62),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: s.spacing(1),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.arrowBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      s.arrow,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
