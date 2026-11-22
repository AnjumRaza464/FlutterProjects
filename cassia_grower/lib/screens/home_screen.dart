import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../data/pack_photos.dart';
import '../data/product_repository.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../state/favourites.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../theme/crop_style.dart';
import '../widgets/account_cards.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/weather_card.dart';
import 'ask_cassia_screen.dart';
import 'more_screen.dart';
import 'product_sheet.dart';

/// The landing screen, section for section as in the approved design: a
/// greeting, the hero banner, quick actions, crops, spotlight and product
/// rails, then help for the grower and how ordering works.
///
/// Everything that promotes a variety for ordering (the hero, Spotlight,
/// Featured) only ever uses varieties that are available. Other rails may
/// list a not-available variety, but its card carries the "Not available
/// yet" stamp.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    this.onShopCrop,
    this.repository,
  });

  /// Switches the bottom-bar tab. Indexes match [RootNav]:
  /// 0 Home · 1 Shop · 2 Crop Doctor · 3 Ask Cassia · 4 Order.
  final void Function(int index) onOpenTab;

  /// Opens the Shop showing one crop (by crop key).
  final void Function(String cropKey)? onShopCrop;

  /// Replaceable in tests; defaults to Firestore.
  final ProductRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ProductRepository _repo =
      widget.repository ?? ProductRepository();
  // Held here so rebuilding the screen (a tab switch, a language change)
  // doesn't restart the live query.
  late final Stream<List<Product>> _products = _repo.watchProducts();

  int _tip = DateTime.now().day;

  void _open(Product p) => showProductSheet(context, p, repository: _repo);

  void _openMore() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MoreScreen()));
  }

  void _ask(String question) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AskCassiaScreen(initialQuestion: question),
    ));
  }

  static String _cropKey(Product p) =>
      p.cropKey.isNotEmpty ? p.cropKey : p.crop.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    // Room for the bottom bar, which the page scrolls underneath.
    final under = MediaQuery.paddingOf(context).bottom;

    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];
        final available = products.where((p) => p.available).toList();

        // The banner and Spotlight show packs that are cut out from their
        // background first; those look best on a colour.
        final stars = [
          ...available.where(PackPhotos.isCutOut),
          ...available.where((p) =>
              !PackPhotos.isCutOut(p) &&
              (p.imageUrl.isNotEmpty || PackPhotos.assetFor(p) != null)),
        ].take(6).toList();

        // Each crop once, in the catalog's display order.
        final crops = <String, String>{};
        for (final p in products) {
          if (p.crop.isNotEmpty) crops.putIfAbsent(_cropKey(p), () => p.crop);
        }

        // What the farmer saved with "Save to favourites", newest first.
        final savedIds = FavouritesScope.maybeOf(context)?.ids ?? const [];
        final favourites = [
          for (final id in savedIds.reversed)
            ...products.where((p) => p.id == id),
        ];

        final fresh = products.where((p) => p.isNew).toList();
        final picks = products.where((p) {
          final crop = p.crop.toLowerCase();
          return crop.contains('tomato') ||
              crop.contains('chilli') ||
              crop.contains('pepper');
        }).toList();

        Widget padded(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

        return ListView(
          padding: EdgeInsets.only(top: 14, bottom: under + 18),
          children: [
            padded(const AccountTopCards()),
            padded(const _Greeting()),
            padded(_Hero(
                products: stars, onShop: () => widget.onOpenTab(1))),
            padded(_Stats(packs: products.length, crops: crops.length)),
            _Marquee(crops: crops.values.toList()),
            padded(_QuickActions(
              onTab: widget.onOpenTab,
              onMore: _openMore,
            )),

            padded(const WeatherCard()),

            if (favourites.isNotEmpty) ...[
              padded(SectionTitle(s.yourFavourites)),
              _Rail(products: favourites, onOpen: _open),
            ],

            if (crops.isNotEmpty) ...[
              padded(SectionTitle(s.shopByCrop)),
              _CropCircles(
                crops: crops,
                onTap: (key) => widget.onShopCrop != null
                    ? widget.onShopCrop!(key)
                    : widget.onOpenTab(1),
              ),
            ],

            if (stars.isNotEmpty) ...[
              padded(SectionTitle('✨ ${s.spotlight}')),
              _Spotlight(products: stars, onOpen: _open),
            ],

            if (available.isNotEmpty) ...[
              padded(SectionTitle(
                s.featuredSeeds,
                action: s.seeAll,
                onAction: () => widget.onOpenTab(1),
              )),
              _Rail(products: available.take(9).toList(), onOpen: _open),
            ] else if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),

            padded(_Promo(onTap: () => widget.onOpenTab(2))),

            if (fresh.isNotEmpty) ...[
              padded(SectionTitle(s.newArrivals)),
              _Rail(products: fresh, onOpen: _open),
            ],
            if (picks.isNotEmpty) ...[
              padded(SectionTitle(s.tomatoChilliPicks)),
              _Rail(products: picks, onOpen: _open),
            ],

            padded(SectionTitle(s.commonProblems)),
            padded(_Problems(onAsk: _ask)),
            padded(_Tip(
              text: s.tips[_tip % s.tips.length],
              onNext: () => setState(() => _tip++),
            )),

            padded(SectionTitle(s.whyCassia)),
            padded(const _Why()),
            padded(SectionTitle(s.fromOurFields)),
            const _Fields(),
            padded(SectionTitle(s.ourBrands)),
            padded(const _Brands()),
            padded(SectionTitle(s.howOrderingWorks)),
            padded(const _Steps()),
            padded(SectionTitle(s.questions)),
            padded(const _Faq()),
            padded(_HelpCta(onAsk: () => widget.onOpenTab(3))),
            _Footer(onOpenTab: widget.onOpenTab, onMore: _openMore),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- greeting

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.greeting(DateTime.now().hour),
              style: TextStyle(color: c.muted, fontSize: 13)),
          Text('${s.salam} 👋',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------- hero

/// The banner: brand message on one side, a seed pack on the other. The pack
/// (and the banner's colours with it) changes every few seconds.
class _Hero extends StatefulWidget {
  const _Hero({required this.products, required this.onShop});

  final List<Product> products;
  final VoidCallback onShop;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  Timer? _timer;
  int _i = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // People who turn animations off on their phone get a still banner.
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (mounted && widget.products.length > 1) setState(() => _i++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final product = widget.products.isEmpty
        ? null
        : widget.products[_i % widget.products.length];
    final style = product == null
        ? const CropStyle('🌱', AppColors.greenLight, Color(0xFF0F3319))
        : CropStyle.of(product.crop);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      constraints: const BoxConstraints(minHeight: 218),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.deep, style.light],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // A soft highlight in the far top corner, and the dotted texture.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.75, -0.7),
                  radius: 0.9,
                  colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          // Leaves drifting down behind the banner content.
          const Positioned.fill(child: _FallingLeaves()),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 8, 34),
            child: Row(
              children: [
                Expanded(
                  flex: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.season,
                          style: TextStyle(
                              color: const Color(0xFFF1D98F),
                              fontSize: 11,
                              letterSpacing: s.spacing(2),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(s.motto,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(s.heroTagline,
                          style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 13,
                              height: 1.35)),
                      const SizedBox(height: 16),
                      PressButton(
                        label: '${s.shopSeedsCta} ${s.arrow}',
                        onTap: widget.onShop,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 42,
                  child: SizedBox(
                    height: 170,
                    child: product == null
                        ? const SizedBox.shrink()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            child: Transform.rotate(
                              key: ValueKey(product.id),
                              angle: 0.1,
                              child: ProductImage.bare(product: product),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The faint grid of dots over the banner and spotlight cards.
class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x1CFFFFFF);
    for (double y = 8; y < size.height; y += 16) {
      for (double x = 8; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => false;
}

/// A few leaf glyphs that drift from the top of the banner to the bottom,
/// rotating and fading as they fall. Purely decorative, so it never takes
/// taps, and it holds still for people who turn animations off.
class _FallingLeaves extends StatefulWidget {
  const _FallingLeaves();

  @override
  State<_FallingLeaves> createState() => _FallingLeavesState();
}

class _FallingLeavesState extends State<_FallingLeaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fall =
      AnimationController(vsync: this, duration: const Duration(seconds: 7));

  static const _count = 7;
  static const _glyphs = ['🌿', '🌱', '🍃'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fall.stop();
    } else if (!_fall.isAnimating) {
      _fall.repeat();
    }
  }

  @override
  void dispose() {
    _fall.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return AnimatedBuilder(
            animation: _fall,
            builder: (context, _) => Stack(
              children: [
                for (var i = 0; i < _count; i++) _leaf(i, w, h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _leaf(int i, double w, double h) {
    // Each leaf is at a different point of its fall (staggered start).
    final phase = (_fall.value + i / _count) % 1.0;
    final left = ((0.06 + i * 0.13) % 1.0) * w;
    final top = -20 + phase * (h + 40);
    final opacity = ((1 - phase) * 0.5).clamp(0.0, 0.5);
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: phase * 2 * math.pi,
          child: Text(_glyphs[i % _glyphs.length],
              style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- stats

/// The strip of four facts that overlaps the bottom of the banner.
class _Stats extends StatelessWidget {
  const _Stats({required this.packs, required this.crops});

  final int packs;
  final int crops;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;

    Widget fact(String big, String small) => Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(big,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.green)),
              ),
              Text(small,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.muted)),
            ],
          ),
        );

    return Transform.translate(
      offset: const Offset(0, -22),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x1F4A2F1B), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            fact('$packs', s.statSeedPacks),
            fact('$crops', s.statCrops),
            fact(s.statYears, s.statTrials),
            fact(s.statAi, s.cropDoctor),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- marquee

/// The green band of crop names that slides slowly across the screen.
class _Marquee extends StatefulWidget {
  const _Marquee({required this.crops});

  final List<String> crops;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide =
      AnimationController(vsync: this, duration: const Duration(seconds: 26));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _slide.stop();
    } else if (!_slide.isAnimating) {
      _slide.repeat();
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crops = widget.crops.isEmpty
        ? const ['Tomato', 'Chilli', 'Okra', 'Carrot', 'Cucumber', 'Brinjal']
        : widget.crops;
    final line = [
      for (final crop in crops) '${CropStyle.of(crop).emoji} $crop',
    ].join('  ·  ');
    final strip = Text('$line  ·  ',
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13));

    return Container(
      height: 40,
      // Crop names are in English, so the band always slides the same way.
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [AppColors.greenLight, AppColors.green]),
        boxShadow: [BoxShadow(color: Color(0xFF17492A), offset: Offset(0, 4))],
      ),
      child: ClipRect(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            // Two copies end to end; sliding by one copy's width loops.
            child: AnimatedBuilder(
              animation: _slide,
              builder: (context, child) => FractionalTranslation(
                translation: Offset(-_slide.value / 2, 0),
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [strip, strip],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- quick actions

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTab, required this.onMore});

  final void Function(int index) onTab;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tiles = [
      ('🩺', s.cropDoctor, () => onTab(2)),
      ('💬', s.askCassia, () => onTab(3)),
      ('🌱', s.seedShop, () => onTab(1)),
      ('🛒', s.myOrder, () => onTab(4)),
      ('📞', s.support, onMore),
      ('🏢', s.aboutUs, onMore),
      ('🚜', s.myFarm, onMore),
      ('📍', s.findDealer, onMore),
      ('🆘', s.help, onMore),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _TileGrid(
        children: [
          for (final (emoji, label, onTap) in tiles)
            _Tile(emoji: emoji, label: label, onTap: onTap, boxed: true),
        ],
      ),
    );
  }
}

/// Three tiles to a row.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 3)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + 3; j++) ...[
                    if (j > i) const SizedBox(width: 10),
                    Expanded(
                      child: j < children.length
                          ? children[j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A raised tile with an emoji and a label.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.boxed = false,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  /// Puts the emoji in a tinted rounded square, as on the quick actions.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: raisedBox(context, radius: 22),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (boxed)
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [c.background, c.line]
                            : const [Color(0xFFEAF3E4), Color(0xFFF6ECD0)],
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  )
                else
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ crop circles

class _CropCircles extends StatelessWidget {
  const _CropCircles({required this.crops, required this.onTap});

  /// Crop key → crop name.
  final Map<String, String> crops;
  final void Function(String cropKey) onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return SizedBox(
      height: 98,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final entry in crops.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () => onTap(entry.key),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.gold, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0xFFA37D2C), offset: Offset(0, 4)),
                          ],
                        ),
                        child: Text(CropStyle.of(entry.value).emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.data(entry.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- spotlight

/// Large swipeable cards, one variety each, on that crop's colours.
class _Spotlight extends StatefulWidget {
  const _Spotlight({required this.products, required this.onOpen});

  final List<Product> products;
  final void Function(Product) onOpen;

  @override
  State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight> {
  final _pages = PageController(viewportFraction: 0.86);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final products = widget.products;
    final onOpen = widget.onOpen;
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pages,
        padEnds: false,
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          final style = CropStyle.of(p.crop);
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 0, 18),
            child: GestureDetector(
              onTap: () => onOpen(p),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: style.gradient,
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), offset: Offset(0, 7)),
                    BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 22,
                        offset: Offset(0, 14)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    const Positioned.fill(
                        child: CustomPaint(painter: _DotsPainter())),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(20, 18, 10, 18),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 54,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s.data(p.crop.toUpperCase()),
                                    style: TextStyle(
                                        color: const Color(0xD9FFFFFF),
                                        fontSize: 12,
                                        letterSpacing: s.spacing(1))),
                                const SizedBox(height: 4),
                                Text(p.name,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800)),
                                if (p.packSize.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(s.data(p.packSize),
                                      style: const TextStyle(
                                          color: Color(0xE6FFFFFF),
                                          fontSize: 13)),
                                ],
                                const SizedBox(height: 14),
                                PressButton(
                                  label: '${s.viewAndOrder} ${s.arrow}',
                                  dense: true,
                                  onTap: () => onOpen(p),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 46,
                            child: Transform.rotate(
                              angle: 0.07,
                              child: ProductImage.bare(product: p),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------ product rail

/// A sideways-scrolling row of product cards.
class _Rail extends StatelessWidget {
  const _Rail({required this.products, required this.onOpen});

  final List<Product> products;
  final void Function(Product) onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Tall enough for the card's picture, two lines of text and the
      // availability pill.
      height: 276,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Space underneath for the cards' shadows.
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 156,
          child: ProductCard(
            product: products[i],
            onTap: () => onOpen(products[i]),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- promo

class _Promo extends StatelessWidget {
  const _Promo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 18, 14, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                colors: [AppColors.brown, Color(0xFF7A5230)]),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x334A2F1B),
                  blurRadius: 20,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🩺 ${s.cropDoctor}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(s.promoBody,
                        style: const TextStyle(
                            color: Color(0xD9FFFFFF), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PressButton(label: s.tryNow, dense: true, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- help sections

class _Problems extends StatelessWidget {
  const _Problems({required this.onAsk});

  final void Function(String question) onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return _TileGrid(
      children: [
        for (final (emoji, name) in s.problems)
          _Tile(
            emoji: emoji,
            label: name,
            onTap: () => onAsk(s.problemQuestion(name)),
          ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text, required this.onNext});

  final String text;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GestureDetector(
        onTap: onNext,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          // A fixed pale wash with dark text, the same in both themes.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
                colors: [Color(0xFFEAF3E4), Color(0xFFF6ECD0)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: '💡 ${s.growerTip}',
                  style: const TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: '  ·  ${s.tapForNext}',
                      style: const TextStyle(
                          color: Color(0x991F5A30),
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: [...previous, ?current],
                ),
                child: Text(
                  text,
                  key: ValueKey(text),
                  style: const TextStyle(
                      color: AppColors.ink, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Why extends StatelessWidget {
  const _Why();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final points = context.s.whyPoints;

    Widget point((String, String) p) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.$1,
                    style: TextStyle(
                        color: c.green, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(p.$2,
                    style: TextStyle(
                        color: c.ink, fontSize: 13, height: 1.35)),
              ],
            ),
          ),
        );

    return Column(
      children: [
        for (var i = 0; i < points.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  point(points[i]),
                  const SizedBox(width: 10),
                  if (i + 1 < points.length)
                    point(points[i + 1])
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = context.s.orderSteps;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Container(
            margin: EdgeInsets.only(top: i == 0 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: raisedBox(context, radius: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gold, Color(0xFFA37D2C)],
                    ),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i].$1,
                          style: TextStyle(
                              color: c.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(steps[i].$2,
                          style: TextStyle(color: c.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        for (final (question, answer) in context.s.faqs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              // No divider lines above and below an open answer.
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: c.green,
                collapsedIconColor: c.muted,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding:
                    const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 14),
                expandedAlignment: AlignmentDirectional.topStart,
                title: Text(question,
                    style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                children: [
                  Text(answer,
                      style: TextStyle(
                          color: c.muted, fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HelpCta extends StatelessWidget {
  const _HelpCta({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143D20), AppColors.greenLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.needHelp,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(s.needHelpBody,
              style: const TextStyle(
                  color: Color(0xE6FFFFFF), fontSize: 13, height: 1.45)),
          const SizedBox(height: 14),
          PressButton(label: s.askCassia, onTap: onAsk),
        ],
      ),
    );
  }
}

/// A sideways row of real photos from the company's fields, each with a
/// caption, matching the "From Our Fields" section of the design.
class _Fields extends StatelessWidget {
  const _Fields();

  static const _photos = [
    'assets/fields/field_day.webp',
    'assets/fields/chilli_crop.webp',
    'assets/fields/cucumber.webp',
    'assets/fields/chilli_field.webp',
  ];

  @override
  Widget build(BuildContext context) {
    final captions = context.s.fieldCaptions;
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
        itemCount: _photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_photos[i], fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 26, 14, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3000000)],
                      ),
                    ),
                    child: Text(
                      captions[i % captions.length],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The company's brand logos (Cassia Seed and Malapine) on light cards so
/// they stay readable in both light and dark themes.
class _Brands extends StatelessWidget {
  const _Brands();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget card(String asset) => Expanded(
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F0),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        );

    return Row(
      children: [
        card('assets/brand/logo.png'),
        const SizedBox(width: 12),
        card('assets/brand/malapine.webp'),
      ],
    );
  }
}

/// The full footer: brand, quick links, the company's promise, head office
/// and brands — on the dark green card used in the approved design.
class _Footer extends StatelessWidget {
  const _Footer({required this.onOpenTab, required this.onMore});

  final void Function(int index) onOpenTab;
  final VoidCallback onMore;

  static const _white = TextStyle(color: Colors.white, fontSize: 13);
  static const _muted = TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4);
  static const _heading = TextStyle(
      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final promise = [for (final p in s.whyPoints) p.$1];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143D20), AppColors.green],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const CassiaLogo(height: 34),
          ),
          const SizedBox(height: 10),
          Text('GROW WITH CASSIA/US',
              style: TextStyle(
                  color: const Color(0xFFF1D98F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: s.spacing(1))),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _column(s.quickLinks, [
                  for (final (label, onTap) in <(String, VoidCallback)>[
                    (s.seedShop, () => onOpenTab(1)),
                    (s.cropDoctor, () => onOpenTab(2)),
                    (s.askCassia, () => onOpenTab(3)),
                    (s.myOrder, () => onOpenTab(4)),
                    (s.support, onMore),
                  ])
                    InkWell(
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(label, style: _muted),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _column(s.ourPromise, [
                  for (final item in promise)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ ', style: TextStyle(fontSize: 13)),
                          Expanded(child: Text(item, style: _muted)),
                        ],
                      ),
                    ),
                ]),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0x33FFFFFF), height: 1),
          ),
          Text(s.headOffice, style: _heading),
          const SizedBox(height: 6),
          Text(AppConfig.companyName, style: _white),
          const SizedBox(height: 2),
          Text(AppConfig.address, style: _muted),
          const SizedBox(height: 16),
          Text(s.ourBrands, style: _heading),
          const SizedBox(height: 4),
          Text(s.brandsLine, style: _muted),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text('© 2026 ${AppConfig.companyName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 11)),
                const SizedBox(height: 2),
                Text(s.designedByOwner,
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 11)),
                Text(s.reachAllPakistan,
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _heading),
          const SizedBox(height: 8),
          ...children,
        ],
      );
}
