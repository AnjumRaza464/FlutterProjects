import 'package:material_ui/material_ui.dart';

import '../data/product_repository.dart';
import '../l10n/app_strings.dart';
import '../state/cart_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/cassia_header.dart';
import 'ask_cassia_screen.dart';
import 'cart_screen.dart';
import 'crop_doctor_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'shop_screen.dart';

/// The app shell, laid out as in the approved design: the white logo header
/// on top, and a bottom bar with five tabs —
/// Home · Shop · Doctor (raised, in the middle) · Ask · Order.
///
/// Support and company details ("More") open from the Home screen's tiles.
class RootNav extends StatefulWidget {
  const RootNav({super.key, this.repository});

  /// The catalog the Home and Shop tabs read. Replaceable in tests; defaults
  /// to Firestore.
  final ProductRepository? repository;

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  /// The crop Home asked the Shop to show (from "Shop by Crop").
  final _shopCrop = ValueNotifier<String?>(null);

  @override
  void dispose() {
    _shopCrop.dispose();
    super.dispose();
  }

  /// The tabs opened on the way here, oldest first — where the header's
  /// back button leads. It starts, like the app, on Home.
  final _trail = <int>[0];

  void _openTab(int i) {
    if (i == _index) return;
    setState(() {
      _index = i;
      _trail.add(i);
      if (_trail.length > 20) _trail.removeAt(0);
    });
  }

  /// Returns to the tab the farmer was on before this one.
  void _back() {
    setState(() {
      if (_trail.length > 1) _trail.removeLast();
      _index = _trail.last;
    });
  }

  /// The header's profile button: settings, support and company details.
  void _openMore() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MoreScreen()));
  }

  void _shopFor(String cropKey) {
    _shopCrop.value = cropKey;
    _openTab(1);
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack keeps each tab's state alive while switching.
    final pages = [
      HomeScreen(
        onOpenTab: _openTab,
        onShopCrop: _shopFor,
        repository: widget.repository,
      ),
      ShopScreen(
        embedded: true,
        repository: widget.repository,
        cropRequest: _shopCrop,
      ),
      const CropDoctorScreen(embedded: true),
      const AskCassiaScreen(embedded: true),
      CartScreen(embedded: true, onBrowse: () => _openTab(1)),
    ];

    return Scaffold(
      // The page scrolls under the bar's rounded corners and raised button.
      extendBody: true,
      appBar: CassiaHeader(
        // Home is where the app starts: there is nothing to go back to.
        onBack: _index == 0 ? null : _back,
        onProfile: _openMore,
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _NavBar(
        index: _index,
        onTap: _openTab,
        cartCount: CartScope.of(context).totalQuantity,
      ),
    );
  }
}

/// The bottom bar: a rounded card with four tabs and, rising out of the
/// middle, the round Crop Doctor button.
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.onTap,
    required this.cartCount,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int cartCount;

  static const double _bar = 64;
  static const double _rise = 26;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final safe = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: _bar + _rise + safe,
      child: Stack(
        children: [
          // The bar itself starts below the part the Doctor button rises
          // into; that strip above it is see-through.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: _rise,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, -8)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: 0,
            bottom: safe,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _tab(context, 0, '🏠', s.navHome),
                _tab(context, 1, '🌱', s.navShop),
                _doctor(context, s.navDoctor),
                _tab(context, 3, '💬', s.navAskAi),
                _tab(context, 4, '🛒', s.navOrder, badge: cartCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, int i, String emoji, String label,
      {int badge = 0}) {
    final c = context.colors;
    final on = i == index;
    return Expanded(
      child: SizedBox(
        height: _bar,
        child: InkWell(
          onTap: () => onTap(i),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22, height: 1.1)),
                  if (badge > 0)
                    PositionedDirectional(
                      top: -5,
                      end: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: on ? c.green : c.muted,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              // A small gold dot marks the tab that is open.
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: on ? c.gold : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doctor(BuildContext context, String label) {
    final c = context.colors;
    return Expanded(
      child: SizedBox(
        height: _bar + _rise,
        child: InkWell(
          onTap: () => onTap(2),
          customBorder: const CircleBorder(),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.greenLight, AppColors.green],
                  ),
                  // A ring in the bar's colour, a solid lip, and a glow.
                  border: Border.all(color: c.card, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF17492A), offset: Offset(0, 5)),
                    BoxShadow(
                        color: Color(0x661F5A30),
                        blurRadius: 18,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: const Text('🩺', style: TextStyle(fontSize: 24)),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: c.green,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
            ],
          ),
        ),
      ),
    );
  }
}
