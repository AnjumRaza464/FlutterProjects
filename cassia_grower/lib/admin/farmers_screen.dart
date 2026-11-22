import 'package:material_ui/material_ui.dart';

import '../models/farmer_profile.dart';
import '../services/launchers.dart';
import '../theme/app_colors.dart';
import 'admin_bar_button.dart';
import 'admin_search_bar.dart';
import 'farmer_admin_service.dart';

/// Admin view of the `farmers` collection: the farmers who have registered in
/// the app, with their area, crops and a quick way to contact them. Read-only
/// — a profile belongs to the farmer. English + light only, like the rest of
/// the admin panel. A search box filters by name, phone, area or crop.
class FarmersScreen extends StatefulWidget {
  const FarmersScreen({super.key, this.service});

  final FarmerAdminService? service;

  @override
  State<FarmersScreen> createState() => _FarmersScreenState();
}

class _FarmersScreenState extends State<FarmersScreen> {
  late final FarmerAdminService _admin =
      widget.service ?? FarmerAdminService();
  // Held so typing in the search box (which rebuilds) doesn't restart the
  // live query and flicker the list.
  late final Stream<List<FarmerProfile>> _farmers = _admin.watchFarmers();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Search by name, phone, area or crop',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: StreamBuilder<List<FarmerProfile>>(
              stream: _farmers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load farmers.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  );
                }
                final all = snapshot.data ?? const <FarmerProfile>[];
                if (all.isEmpty) {
                  return const Center(
                    child: Text('No registered farmers yet.',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }
                final farmers =
                    all.where((f) => _matches(f, _query)).toList();
                if (farmers.isEmpty) {
                  return Center(
                    child: Text('No farmers match "$_query".',
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
                                    ? '${farmers.length} registered'
                                    : '${farmers.length} of ${all.length}',
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                            itemCount: farmers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) =>
                                _FarmerCard(farmer: farmers[i]),
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

  /// True when every word typed appears somewhere in the farmer's name, phone,
  /// area or crops.
  static bool _matches(FarmerProfile f, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [f.name, f.phone, f.district, f.village, ...f.crops]
        .join(' ')
        .toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }
}

class _FarmerCard extends StatelessWidget {
  const _FarmerCard({required this.farmer});

  final FarmerProfile farmer;

  /// The number WhatsApp / the dialer needs (digits with country code).
  String get _dialNumber {
    final d = farmer.phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) return '92${d.substring(1)}';
    if (d.length == 10) return '92$d';
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final place =
        [farmer.village, farmer.district].where((e) => e.isNotEmpty).join(', ');
    final hasPhone = _dialNumber.length >= 11;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFEAF3E4),
                child: Text('🧑‍🌾', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.name.isNotEmpty ? farmer.name : 'Farmer',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (farmer.phone.isNotEmpty)
                      Text('📱 ${farmer.phone}',
                          style: const TextStyle(color: AppColors.muted)),
                    if (place.isNotEmpty)
                      Text('📍 $place',
                          style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          if (farmer.crops.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final crop in farmer.crops)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EFE6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(crop,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ],
          if (hasPhone) ...[
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Launchers.openWebsite('https://wa.me/$_dialNumber'),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Launchers.dialPhone(_dialNumber),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// App-bar button for the admin dashboard: opens the Farmers list.
class FarmersButton extends StatelessWidget {
  const FarmersButton({super.key, this.service});

  final FarmerAdminService? service;

  @override
  Widget build(BuildContext context) {
    return AdminBarButton(
      icon: Icons.people_outline,
      label: 'Farmers',
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FarmersScreen(service: service),
      )),
    );
  }
}
