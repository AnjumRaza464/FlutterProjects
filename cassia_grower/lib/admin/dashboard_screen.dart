import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/product_repository.dart';
import '../data/sample_products.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../widgets/product_image.dart';
import 'admin_bar_button.dart';
import 'admin_search_bar.dart';
import 'dealers_screen.dart';
import 'farmers_screen.dart';
import 'orders_screen.dart';
import 'product_admin_service.dart';
import 'product_form_screen.dart';

/// Admin dashboard: lists every product (available and not), with a search box,
/// quick availability toggles, edit, delete, and an "add product" button. The
/// app bar's labelled actions open Farmers, Dealers and Orders, and sign out.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = ProductRepository();
  final _admin = ProductAdminService();
  // Held so typing in the search box doesn't restart the live query.
  late final Stream<List<Product>> _products = _repo.watchProducts();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        actions: [
          const FarmersButton(),
          const DealersButton(),
          const OrdersButton(),
          AdminBarButton(
            icon: Icons.logout,
            label: 'Sign out',
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Search by name, crop, type or pack size',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load products.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  );
                }
                final all = snapshot.data ?? const <Product>[];
                if (all.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No products yet.',
                            style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => _loadDemo(context),
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Load 15 demo products'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.green,
                            side: const BorderSide(color: AppColors.green),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Or tap "Add product" to create your own.',
                            style:
                                TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  );
                }
                final products =
                    all.where((p) => p.matchesSearch(_query)).toList();
                if (products.isEmpty) {
                  return Center(
                    child: Text('No products match "$_query".',
                        style: const TextStyle(color: AppColors.muted)),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                          child: Row(
                            children: [
                              Text(
                                _query.isEmpty
                                    ? '${products.length} products'
                                    : '${products.length} of ${all.length}',
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 10, 16, 90),
                            itemCount: products.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) =>
                                _row(context, products[i], _admin),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Product p, ProductAdminService admin) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ProductImage(product: p),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      p.crop,
                      if (p.packSize.isNotEmpty) p.packSize,
                      'sort ${p.sortOrder}',
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Quick available toggle.
            Column(
              children: [
                Switch(
                  value: p.available,
                  activeThumbColor: AppColors.green,
                  onChanged: (v) => admin.setAvailable(p.id, v),
                ),
                Text(p.available ? 'Available' : 'Hidden',
                    style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, color: AppColors.green),
              onPressed: () => _openForm(context, existing: p),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
              onPressed: () => _confirmDelete(context, p, admin),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Product? existing}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProductFormScreen(existing: existing),
    ));
  }

  /// Writes the 15 demo products to Firestore. Works here (unlike the app's
  /// old button) because the admin is signed in, so it passes the security
  /// rules. For previewing/testing before the real catalog is ready.
  Future<void> _loadDemo(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Loading demo products…')),
    );
    try {
      await seedSampleProducts();
      messenger.showSnackBar(
        const SnackBar(content: Text('Loaded 15 demo products.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not load demo products: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, Product p, ProductAdminService admin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${p.name}" will be permanently removed from the '
            'catalog. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await admin.delete(p.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${p.name}".')),
        );
      }
    }
  }
}
