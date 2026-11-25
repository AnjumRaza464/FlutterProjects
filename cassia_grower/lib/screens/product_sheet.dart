import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../data/pack_photos.dart';
import '../data/product_repository.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../services/ai_failure.dart';
import '../services/ask_cassia_service.dart';
import '../state/cart_scope.dart';
import '../state/favourites.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/ai_coming_soon.dart';
import '../widgets/availability_pill.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/not_available_badge.dart';
import '../widgets/product_image.dart';
import 'ask_cassia_screen.dart';

/// Opens a variety's details in a sheet that slides up over the current
/// page, as in the approved design.
Future<void> showProductSheet(
  BuildContext context,
  Product product, {
  ProductRepository? repository,
  AskCassiaService? askService,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x88000000),
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => ProductSheet(
      product: product,
      repository: repository,
      askService: askService,
    ),
  );
}

/// Everything about one variety: its photos, its facts and features, and the
/// buttons to order it, ask about it or save it.
///
/// Not-available varieties are still fully openable — the details, "Ask
/// Cassia" and favourites keep working so the variety can be promoted and
/// explained. But the photo carries the "Not available yet" stamp, there is
/// no quantity to choose, and the order button is switched off and reads
/// "Coming Soon", so nothing looks like it is on sale.
class ProductSheet extends StatefulWidget {
  const ProductSheet({
    super.key,
    required this.product,
    this.repository,
    this.askService,
  });

  final Product product;

  /// Replaceable in tests; defaults to Firestore.
  final ProductRepository? repository;

  /// Answers "General crop guide (AI)". Replaceable in tests; defaults to
  /// the real Cloud Function client.
  final AskCassiaService? askService;

  /// The most packs that can be added in one go.
  static const maxPacks = 99;

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  // Stream the product so flipping availability in the admin panel updates
  // this open sheet instantly. Held here so a rebuild doesn't restart it.
  late final Stream<Product?> _product =
      (widget.repository ?? ProductRepository())
          .watchProduct(widget.product.id);

  final _gallery = PageController();
  int _photo = 0;
  bool _showFeatures = false;
  int _packs = 1;

  // The AI crop guide: nothing until it is asked for.
  bool _guideLoading = false;
  String? _guide;

  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  void _setPacks(int packs) =>
      setState(() => _packs = packs.clamp(1, ProductSheet.maxPacks));

  void _addToOrder(Product p) {
    // The cart refuses a variety that is not available.
    if (!CartScope.read(context).add(p, quantity: _packs)) return;
    showToast(context, context.s.addedToOrder(_packs, p.name));
    showSeedBurst(context);
    Navigator.of(context).pop();
  }

  void _askCassia(Product p) {
    if (AppConfig.aiComingSoon) {
      showAiComingSoon(context, emoji: '💬', title: context.s.askCassia);
      return;
    }
    final question = context.s.growingQuestion(p.crop, p.name);
    Navigator.of(context)
      ..pop()
      ..push(MaterialPageRoute(
        builder: (_) => AskCassiaScreen(product: p, initialQuestion: question),
      ));
  }

  void _toggleFavourite(Product p) {
    final favourites = FavouritesScope.maybeOf(context);
    if (favourites == null) return;
    final s = context.s;
    final saved = favourites.toggle(p.id);
    showToast(context, saved ? s.savedToFavourites : s.removedFromFavourites);
  }

  /// Asks the AI for a general guide to growing this crop — never for
  /// facts about this variety, which only Cassia can supply.
  Future<void> _loadGuide(Product p) async {
    if (AppConfig.aiComingSoon) {
      showAiComingSoon(context, emoji: '💬', title: context.s.askCassia);
      return;
    }
    if (_guideLoading) return;
    final s = context.s;
    setState(() => _guideLoading = true);

    String text;
    try {
      final reply = await (widget.askService ?? AskCassiaService()).ask(
        [
          ChatMessage.user(
              'Give a short general growing guide for ${p.crop} for farmers '
              'in Sindh and Punjab, Pakistan: best sowing season, spacing, '
              'soil and irrigation, common pests and diseases, and signs of '
              'harvest. This is general crop guidance, NOT data about a '
              'specific variety, so do not claim variety traits. Plain '
              'text, under 150 words.'),
        ],
        language: s.languageCode,
      );
      text = '$reply\n\n${s.cropGuideNote}';
    } on AiFailure catch (e) {
      text = switch (e.kind) {
        AiFailureKind.notSetUp => s.notSetUpBody,
        AiFailureKind.offline => s.noConnectionBody,
        AiFailureKind.other => s.somethingWentWrong,
      };
    } catch (_) {
      text = s.somethingWentWrong;
    }

    if (!mounted) return;
    setState(() {
      _guideLoading = false;
      _guide = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      // Never the whole screen: a strip of the page stays visible above.
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      child: Material(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: StreamBuilder<Product?>(
          stream: _product,
          initialData: widget.product,
          builder: (context, snapshot) {
            final p = snapshot.data ?? widget.product;
            return SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(18, 18, 18, 22 + media.padding.bottom),
              child: _content(p),
            );
          },
        ),
      ),
    );
  }

  Widget _content(Product p) {
    final c = context.colors;
    final s = context.s;
    final favourites = FavouritesScope.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _photos(p),
        Text(
          p.name,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: c.ink),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AvailabilityPill(available: p.available, large: true),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TabButton(
                label: s.tabDetails,
                selected: !_showFeatures,
                onTap: () => setState(() => _showFeatures = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TabButton(
                label: s.tabFeatures,
                selected: _showFeatures,
                onTap: () => setState(() => _showFeatures = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_showFeatures) ..._features(p) else ..._details(p),
        if (p.available) _quantityRow(),
        const SizedBox(height: 10),
        BlockButton(
          label: p.available ? s.addToOrder(_packs) : s.comingSoon,
          onTap: p.available ? () => _addToOrder(p) : null,
        ),
        const SizedBox(height: 12),
        BlockButton(
          label: s.askAboutThisSeed,
          outlined: true,
          onTap: () => _askCassia(p),
        ),
        if (favourites != null) ...[
          const SizedBox(height: 12),
          BlockButton(
            label: favourites.contains(p.id)
                ? s.savedFavourite
                : s.saveToFavourites,
            outlined: true,
            onTap: () => _toggleFavourite(p),
          ),
        ],
      ],
    );
  }

  // ------------------------------------------------------------- photos

  /// The gallery — front, close-up, showcase — with its dots, and the close
  /// button on its corner.
  Widget _photos(Product p) {
    final s = context.s;
    final extras = PackPhotos.extraAssetsFor(p);
    final wash = BoxDecoration(gradient: ProductImage.washOf(context, p));

    // The pack itself, clear of the slide's edges.
    Widget pack() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: ProductImage.bare(product: p),
        );

    // An extra photo of the pack fills the slide.
    Widget extra(String asset, Widget fallback) => Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) => fallback,
        );

    final closeUp = Transform.scale(
      scale: 2.1,
      alignment: const Alignment(0, 0.12),
      child: pack(),
    );
    final showcase = Transform.rotate(
      angle: -12 * math.pi / 180,
      child: Transform.scale(scale: 0.82, child: pack()),
    );

    // When the admin has uploaded a gallery (2+ photos), show those photos as
    // the slides. With 0–1 uploaded photo we keep the original bundled look
    // (front / close-up / showcase), where the single photo already appears.
    final slides = p.imageUrls.length >= 2
        ? [
            for (var i = 0; i < p.imageUrls.length; i++)
              _Slide(
                label: '${i + 1} / ${p.imageUrls.length}',
                decoration: wash,
                stamp:
                    (i == 0 && !p.available) ? const NotAvailableBadge() : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.network(
                    p.imageUrls[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                ),
                              ),
                    errorBuilder: (context, error, stack) =>
                        ProductImage.bare(product: p),
                  ),
                ),
              ),
          ]
        : [
            _Slide(
              label: s.photoFront,
              decoration: wash,
              stamp: p.available ? null : const NotAvailableBadge(),
              child: _Sway(child: pack()),
            ),
            _Slide(
              label: s.photoCloseUp,
              decoration: wash,
              child: extras.isNotEmpty ? extra(extras[0], closeUp) : closeUp,
            ),
            _Slide(
              label: s.photoShowcase,
              // A dark stage with a spotlight on the pack.
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2218), Color(0xFF0F0C08)],
                ),
              ),
              foreground: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.44),
                  radius: 0.67,
                  colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
              child: extras.length > 1 ? extra(extras[1], showcase) : showcase,
            ),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 260,
              child: DragScroll(
                child: PageView(
                  controller: _gallery,
                  onPageChanged: (i) => setState(() => _photo = i),
                  children: slides,
                ),
              ),
            ),
            PositionedDirectional(
              top: -4,
              end: -4,
              child: _CloseButton(onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
        // One dot per photo; tapping a dot goes to its photo.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _gallery.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == _photo ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _photo
                          ? AppColors.greenLight
                          : context.colors.line,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------- details / features

  /// The facts about the pack. There is no price in the app: Cassia Seed
  /// quotes it when the order is sent.
  List<Widget> _details(Product p) {
    final s = context.s;
    return [
      _Fact(s.brandLabel,
          p.brandLine.isNotEmpty ? s.data(p.brandLine) : s.cassiaBrand),
      if (p.crop.isNotEmpty) _Fact(s.cropLabel, s.data(s.cropName(p.crop))),
      if (p.type.isNotEmpty) _Fact(s.typeLabel, s.data(p.type)),
      _Fact(s.packSizeLabel,
          p.packSize.isNotEmpty ? s.data(s.packSize(p.packSize)) : s.askCompany),
      _Fact(s.priceLabel, s.onRequest),
    ];
  }

  /// What Cassia says about the variety, and a general guide to its crop.
  List<Widget> _features(Product p) {
    final c = context.colors;
    final s = context.s;
    final guide = _guide;
    return [
      if (p.printedInfo.isNotEmpty)
        _Fact(s.printedOnPack, s.data(p.printedInfo)),
      if (p.features.isNotEmpty)
        for (final feature in p.features)
          _Line(
            child: Text(
              '✅ ${s.data(feature)}',
              style: TextStyle(color: c.ink, fontSize: 14),
            ),
          )
      else
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            s.featuresToCome,
            style: TextStyle(color: c.muted, fontSize: 12),
          ),
        ),
      const SizedBox(height: 10),
      BlockButton(
        label: s.cropGuideButton,
        outlined: true,
        onTap: _guideLoading ? null : () => _loadGuide(p),
      ),
      if (_guideLoading || guide != null)
        Container(
          margin: const EdgeInsets.only(top: 19),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: guide == null
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : Text(
                  guide,
                  style: TextStyle(color: c.ink, fontSize: 14, height: 1.45),
                ),
        ),
      const SizedBox(height: 6),
    ];
  }

  // ------------------------------------------------------------ quantity

  Widget _quantityRow() {
    final c = context.colors;
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              s.quantityPacks,
              style: TextStyle(
                  color: c.ink, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          _RoundButton(
            symbol: '−',
            tooltip: s.decrease,
            onTap: () => _setPacks(_packs - 1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Text(
              '$_packs',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.ink, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          _RoundButton(
            symbol: '+',
            tooltip: s.increase,
            onTap: () => _setPacks(_packs + 1),
          ),
        ],
      ),
    );
  }
}

/// One photo of the gallery: a rounded stage with the picture on it and a
/// small label at the foot.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.label,
    required this.decoration,
    required this.child,
    this.foreground,
    this.stamp,
  });

  final String label;
  final BoxDecoration decoration;

  /// Painted over [decoration] but under the picture.
  final BoxDecoration? foreground;
  final Widget child;

  /// Laid over the whole photo: the "Not available yet" stamp.
  final Widget? stamp;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: decoration),
          if (foreground != null) DecoratedBox(decoration: foreground!),
          child,
          ?stamp,
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x77000000),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns the pack gently from side to side, as if it were standing on a
/// slowly swinging shelf. Still where the phone asks for no animations.
class _Sway extends StatefulWidget {
  const _Sway({required this.child});

  final Widget child;

  @override
  State<_Sway> createState() => _SwayState();
}

class _SwayState extends State<_Sway> with SingleTickerProviderStateMixin {
  static const _reach = 18 * math.pi / 180;

  late final _swing =
      AnimationController(vsync: this, duration: const Duration(seconds: 2));
  late final _eased = CurvedAnimation(parent: _swing, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _swing
        ..stop()
        ..value = 0.5;
    } else if (!_swing.isAnimating) {
      _swing.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _eased.dispose();
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _eased,
      child: widget.child,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 1 / 600) // a little perspective
          ..rotateY(_reach * (_eased.value * 2 - 1)),
        child: child,
      ),
    );
  }
}

/// The round ✕ on the corner of the gallery.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.s.close,
      child: Material(
        color: const Color(0x77000000),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// "Details" or "Features": a tab that looks like the design's raised
/// buttons, green when it is the one being shown.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.greenLight : c.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: selected ? const Color(0xFF17492A) : c.line,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : c.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of the sheet with the design's hairline under it.
class _Line extends StatelessWidget {
  const _Line({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: child,
    );
  }
}

/// One "label ... value" row of the facts.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Line(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.muted, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: c.ink, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round − or + button of the quantity picker.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.symbol,
    required this.tooltip,
    required this.onTap,
  });

  final String symbol;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.card,
        shape: CircleBorder(side: BorderSide(color: c.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(color: c.ink, fontSize: 18, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
