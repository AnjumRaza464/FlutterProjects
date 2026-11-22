import 'package:material_ui/material_ui.dart';

import '../data/pack_photos.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../theme/app_palette.dart';
import '../theme/crop_style.dart';

/// A product's picture on a soft colour wash.
///
/// It shows, in order of preference: the photo uploaded for the product in
/// the admin panel, the bundled photo of that seed pack, or — when there is
/// no photo at all — the crop's emoji on the crop's colours.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.padding = const EdgeInsets.all(10),
    this.bare = false,
  });

  /// Just the picture, with no colour wash behind it — for banners that
  /// already have their own background.
  const ProductImage.bare({super.key, required this.product})
      : fit = BoxFit.contain,
        padding = EdgeInsets.zero,
        bare = true;

  final bool bare;

  final Product product;

  /// How an uploaded photo fills the space. Pack photos are always shown
  /// whole (contained), never cropped.
  final BoxFit fit;

  /// Space left around a pack photo.
  final EdgeInsets padding;

  /// The colour wash that goes behind [product]'s picture.
  ///
  /// A cut-out pack sits on colour — its own pack's colours where it has
  /// them, otherwise its crop's. A pack photographed on its own background
  /// gets a quiet neutral wash instead.
  static Gradient washOf(BuildContext context, Product product) {
    const begin = Alignment.topLeft;
    const end = Alignment.bottomRight;
    if (product.imageUrl.isEmpty && PackPhotos.isCutOut(product)) {
      final own = PackPhotos.washFor(product);
      if (own == null) return CropStyle.of(product.crop).gradient;
      return LinearGradient(
          begin: begin, end: end, colors: [Color(own.$1), Color(own.$2)]);
    }
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: begin,
      end: end,
      colors: dark
          ? [c.card, c.background]
          : const [Color(0xFFF3ECDB), Color(0xFFE3EFDC)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl.isNotEmpty) {
      return Image.network(
        product.imageUrl,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: context.colors.line,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        },
        errorBuilder: (context, error, stack) => _bundledOrPlaceholder(context),
      );
    }
    return _bundledOrPlaceholder(context);
  }

  Widget _bundledOrPlaceholder(BuildContext context) {
    final asset = PackPhotos.assetFor(product);
    if (bare) {
      final emoji = Center(
        child: Text(CropStyle.of(product.crop).emoji,
            style: const TextStyle(fontSize: 72)),
      );
      if (asset == null) return emoji;
      return Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) => emoji,
      );
    }
    if (asset == null) return _placeholder(context);

    final cutOut = PackPhotos.isCutOut(product);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: washOf(context, product)),
      child: Padding(
        padding: padding,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // A soft shadow on the "floor" under the pack.
            Align(
              alignment: const Alignment(0, 0.96),
              child: FractionallySizedBox(
                widthFactor: 0.62,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(cutOut ? 0 : 6),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stack) => _placeholder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final style = CropStyle.of(product.crop);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: style.gradient),
      // Shrinks to fit a small space, such as the thumbnail in the cart.
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(style.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Text(
                product.crop.isNotEmpty
                    ? product.crop
                    : context.s.seedPlaceholder,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
