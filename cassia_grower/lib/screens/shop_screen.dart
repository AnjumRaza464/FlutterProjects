import 'package:material_ui/material_ui.dart';

import '../data/crop_groups.dart';
import '../data/product_repository.dart';
import '../data/sample_products.dart';
import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/cart_button.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/product_card.dart';
import 'product_sheet.dart';

/// The catalog. Reads live from Firestore so flipping availability in the
/// admin panel is reflected here instantly. Available varieties sort to the
/// top; not-available ones stay visible below with the overlay.
///
/// A search box and a row of group chips ("Tomato", "Gourds", "Other Veg")
/// narrow the list. They only ever narrow it by what a variety is: a
/// not-available variety that matches is still shown, with its overlay,
/// exactly as in the full list.
class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    this.repository,
    this.embedded = false,
    this.cropRequest,
  });

  /// Replaceable in tests; defaults to Firestore.
  final ProductRepository? repository;

  /// True when shown as a tab under the app's shared header: the screen then
  /// has no bar of its own and shows its name as a page title instead.
  final bool embedded;

  /// Lets another screen (Home's "Shop by Crop") ask for one crop to be
  /// shown, by setting its crop key. The Shop shows that crop's group.
  final ValueNotifier<String?>? cropRequest;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ProductRepository _repo =
      widget.repository ?? ProductRepository();
  // Held here so rebuilding the screen doesn't restart the live query.
  late final Stream<List<Product>> _products = _repo.watchProducts();

  /// The group being shown; null shows every variety.
  CropGroup? _group;

  /// The search box. What is typed narrows the list further, on top of the
  /// chosen group.
  final _search = TextEditingController();

  String get _query => _search.text.trim();

  @override
  void initState() {
    super.initState();
    widget.cropRequest?.addListener(_onCropRequest);
    final crop = widget.cropRequest?.value;
    if (crop != null) _group = CropGroup.ofCrop(crop);
  }

  /// Home asked for a crop: show its group, on a clean search.
  void _onCropRequest() {
    final crop = widget.cropRequest?.value;
    if (crop == null) return;
    _search.clear();
    setState(() => _group = CropGroup.ofCrop(crop));
  }

  @override
  void dispose() {
    widget.cropRequest?.removeListener(_onCropRequest);
    _search.dispose();
    super.dispose();
  }

  /// Back to the whole catalog: no search, no group.
  void _showAll() {
    _search.clear();
    setState(() => _group = null);
  }

  /// The groups that have at least one variety, in the design's order.
  static List<CropGroup> _groupsIn(List<Product> products) {
    final present = {for (final p in products) CropGroup.of(p)};
    return [
      for (final group in CropGroup.values)
        if (present.contains(group)) group,
    ];
  }

  String _label(CropGroup group) {
    final s = context.s;
    return switch (group) {
      CropGroup.tomato => s.groupTomato,
      CropGroup.pepper => s.groupPepper,
      CropGroup.gourd => s.groupGourds,
      CropGroup.okra => s.groupOkra,
      CropGroup.veg => s.groupOtherVeg,
      CropGroup.field => s.groupFieldCrops,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(context.s.seedShop),
              actions: const [CartButton(), SizedBox(width: 4)],
            ),
      body: StreamBuilder<List<Product>>(
        stream: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _error(snapshot.error.toString());
          }
          final products = snapshot.data ?? const [];
          if (products.isEmpty) {
            return _empty();
          }

          final groups = _groupsIn(products);
          // If the chosen group has left the catalog, go back to showing all.
          final chosen = groups.contains(_group) ? _group : null;
          final query = _query;
          final shown = [
            for (final p in products)
              if ((chosen == null || CropGroup.of(p) == chosen) &&
                  p.matchesSearch(query))
                p,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.embedded)
                PageTitle(context.s.seedShop,
                    subtitle: context.s.seedShopHint),
              _searchBox(),
              // With a single group there is nothing to choose between.
              if (groups.length > 1) _filterBar(groups, chosen),
              Expanded(
                child: shown.isEmpty
                    ? _noMatches(query)
                    : _grid(shown, '${chosen?.name}|$query'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    final c = context.colors;
    final s = context.s;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(99),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: s.searchSeeds,
          hintStyle: TextStyle(color: c.muted),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Icon(Icons.search, color: c.muted),
          ),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.close),
                  tooltip: s.clearSearch,
                ),
          isDense: true,
          filled: true,
          fillColor: c.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: border(c.line),
          enabledBorder: border(c.line),
          focusedBorder: border(c.green, 1.5),
        ),
      ),
    );
  }

  /// Shown when the search (with the chosen group) leaves nothing to list.
  Widget _noMatches(String query) {
    final c = context.colors;
    final s = context.s;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: c.muted),
            const SizedBox(height: 12),
            Text(
              s.noMatches(query),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: c.ink),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _showAll,
              child: Text(s.showAllVarieties),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(List<CropGroup> groups, CropGroup? chosen) {
    return DragScroll(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Room underneath for the chips' lips.
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 7),
        child: Row(
          children: [
            ShopChip(
              label: context.s.allCrops,
              selected: chosen == null,
              onTap: () => setState(() => _group = null),
            ),
            for (final group in groups)
              ShopChip(
                label: _label(group),
                selected: group == chosen,
                onTap: () => setState(() => _group = group),
              ),
          ],
        ),
      ),
    );
  }

  /// [filter] identifies the group and search in force. It keys the grid, so
  /// changing either one starts the new list at the top.
  Widget _grid(List<Product> products, String filter) {
    return GridView.builder(
      key: ValueKey(filter),
      // Extra room at the bottom for the cards' shadows and, as a tab, for
      // the bottom bar the grid scrolls under.
      padding: EdgeInsets.fromLTRB(
          16, 8, 16, 20 + MediaQuery.paddingOf(context).bottom),
      // Scrolling the results puts the keyboard away.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      // A fixed height, as in the design: the picture stays the same size
      // however wide the phone is, with room under it for the text.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 18,
        crossAxisSpacing: 12,
        mainAxisExtent: 258,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return ProductCard(
          product: p,
          onTap: () => showProductSheet(context, p, repository: _repo),
        );
      },
    );
  }

  Widget _empty() {
    final c = context.colors;
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: c.green.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(
              s.noProductsYet,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              s.noProductsBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
            const SizedBox(height: 22),
            // Developer convenience: load clearly-labelled demo products so
            // the catalog can be previewed before the real data is imported.
            // Not translated — it isn't meant for farmers.
            OutlinedButton.icon(
              onPressed: _seed,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Load demo products (dev)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.muted,
                side: BorderSide(color: c.line),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seed() async {
    try {
      await seedSampleProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo products loaded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load demo products: $e')),
        );
      }
    }
  }

  Widget _error(String message) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 56, color: c.muted),
            const SizedBox(height: 12),
            Text(context.s.couldNotLoadProducts,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// One chip of the Shop's filter row: a pill on a solid lip, green when it
/// is the group being shown.
class ShopChip extends StatelessWidget {
  const ShopChip({
    super.key,
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
    // The green is the same in both themes, as in the design.
    final face = selected ? AppColors.greenLight : c.card;
    final edge = selected ? AppColors.greenLight : c.line;
    final lip = selected ? const Color(0xFF17492A) : c.line;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: edge),
              boxShadow: [BoxShadow(color: lip, offset: const Offset(0, 3))],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : c.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
