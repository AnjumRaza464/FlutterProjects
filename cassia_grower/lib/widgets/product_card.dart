import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'availability_pill.dart';
import 'not_available_badge.dart';
import 'product_image.dart';

/// A tappable catalog tile: the pack photo, a type tag, a NEW ribbon, the
/// variety's name and crop, and a pill saying whether it can be ordered.
///
/// Not-available products stay fully visible (and openable) but get the
/// "Not available yet" overlay on the image as well as the orange pill.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Container(
      // The "raised" look of the design: a solid lip under a soft shadow.
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(color: c.line, offset: const Offset(0, 5)),
          const BoxShadow(
              color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Picture with overlays ---
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(product: product),
                        if (product.type.isNotEmpty)
                          PositionedDirectional(
                            top: 8,
                            start: 8,
                            // The design's green, the same in both themes.
                            child: _tag(
                                s.data(product.type), AppColors.greenLight),
                          ),
                        // "NEW" never sits on something that can't be ordered.
                        if (product.isNew && product.available)
                          PositionedDirectional(
                            top: 8,
                            end: 0,
                            child: _ribbon(s.newBadge, s.spacing(0.5)),
                          ),
                        if (!product.available)
                          const NotAvailableBadge(compact: true),
                      ],
                    ),
                  ),
                ),
                // --- Text ---
                const SizedBox(height: 8),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  s.data([
                    product.crop,
                    if (product.packSize.isNotEmpty) product.packSize,
                  ].join(' · ')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // --- Whether it can be ordered ---
                AvailabilityPill(available: product.available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _ribbon(String text, double spacing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadiusDirectional.horizontal(
            start: Radius.circular(6)),
        boxShadow: [BoxShadow(color: Color(0xFF8E1B1B), offset: Offset(0, 3))],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: spacing,
        ),
      ),
    );
  }
}
