import 'package:material_ui/material_ui.dart';

import '../models/dealer_account.dart';
import '../theme/app_colors.dart';
import 'admin_bar_button.dart';
import 'admin_search_bar.dart';
import 'dealer_admin_service.dart';

/// Admin view of the `dealers` collection: review applications and keep each
/// dealer's balance, tier and awards up to date. English + light only, like
/// the rest of the admin panel.
class DealersScreen extends StatefulWidget {
  const DealersScreen({super.key, this.service});

  final DealerAdminService? service;

  @override
  State<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends State<DealersScreen> {
  late final DealerAdminService _admin =
      widget.service ?? DealerAdminService();
  // Held so typing in the search box doesn't restart the live query.
  late final Stream<List<DealerAccount>> _dealers = _admin.watchDealers();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dealers')),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Search by name, shop, phone, city or status',
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: StreamBuilder<List<DealerAccount>>(
              stream: _dealers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load dealers.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted)),
                    ),
                  );
                }
                final all = snapshot.data ?? const <DealerAccount>[];
                if (all.isEmpty) {
                  return const Center(
                    child: Text('No dealer accounts yet.',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }
                final dealers =
                    all.where((d) => _matches(d, _query)).toList();
                if (dealers.isEmpty) {
                  return Center(
                    child: Text('No dealers match "$_query".',
                        style: const TextStyle(color: AppColors.muted)),
                  );
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                      itemCount: dealers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _DealerCard(dealer: dealers[i], admin: _admin),
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

  /// True when every word typed appears in the dealer's owner, shop, phone,
  /// city, district, status or awards.
  static bool _matches(DealerAccount d, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = [
      d.ownerName,
      d.businessName,
      d.phone,
      d.city,
      d.district,
      d.status.label,
      ...d.awards,
    ].join(' ').toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }
}

class _DealerCard extends StatelessWidget {
  const _DealerCard({required this.dealer, required this.admin});

  final DealerAccount dealer;
  final DealerAdminService admin;

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dealer.businessName.isNotEmpty
                          ? dealer.businessName
                          : dealer.ownerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (dealer.businessName.isNotEmpty &&
                        dealer.ownerName.isNotEmpty)
                      Text(dealer.ownerName,
                          style: const TextStyle(color: AppColors.muted)),
                    Text('📱 ${dealer.phone}',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              _statusChip(dealer.status),
            ],
          ),
          const SizedBox(height: 10),
          if (dealer.city.isNotEmpty || dealer.district.isNotEmpty)
            _line('Location',
                [dealer.city, dealer.district].where((e) => e.isNotEmpty).join(', ')),
          if (dealer.shopAddress.isNotEmpty) _line('Address', dealer.shopAddress),
          if (dealer.products.isNotEmpty) _line('Sells', dealer.products),
          if (dealer.notes.isNotEmpty) _line('Notes', dealer.notes),
          if (dealer.isApproved) ...[
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                    child: _stat('Balance',
                        'Rs ${dealer.outstandingBalance.round()}')),
                Expanded(
                    child: _stat('Purchases',
                        'Rs ${dealer.totalPurchases.round()}')),
                Expanded(
                    child: _stat(
                        'Tier', dealer.tier.isEmpty ? '—' : dealer.tier)),
              ],
            ),
            if (dealer.awards.isNotEmpty)
              _line('Awards', dealer.awards.join(', ')),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (dealer.isPending) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => admin.approve(dealer.uid),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => admin.reject(dealer.uid),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editLedger(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit balance / tier / awards'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editLedger(BuildContext context) async {
    final balance = TextEditingController(
        text: dealer.outstandingBalance == 0
            ? ''
            : dealer.outstandingBalance.round().toString());
    final purchases = TextEditingController(
        text: dealer.totalPurchases == 0
            ? ''
            : dealer.totalPurchases.round().toString());
    final tier = TextEditingController(text: dealer.tier);
    final awards = TextEditingController(text: dealer.awards.join(', '));
    final perks = TextEditingController(text: dealer.perks.join(', '));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dealer.businessName.isNotEmpty
            ? dealer.businessName
            : dealer.ownerName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(balance, 'Outstanding balance (Rs)',
                  number: true),
              _dialogField(purchases, 'Total purchases (Rs)', number: true),
              _dialogField(tier, 'Tier (e.g. Gold)'),
              _dialogField(awards, 'Awards (comma separated)'),
              _dialogField(perks, 'Benefits (comma separated)'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      List<String> split(String v) => v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await admin.setAccount(
        dealer.uid,
        outstandingBalance: num.tryParse(balance.text.trim()) ?? 0,
        totalPurchases: num.tryParse(purchases.text.trim()) ?? 0,
        tier: tier.text.trim(),
        awards: split(awards.text),
        perks: split(perks.text),
      );
    }

    for (final c in [balance, purchases, tier, awards, perks]) {
      c.dispose();
    }
  }

  Widget _dialogField(TextEditingController c, String label,
      {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }

  Widget _statusChip(DealerStatus status) {
    final color = switch (status) {
      DealerStatus.approved => AppColors.green,
      DealerStatus.pending => const Color(0xFFB8860B),
      DealerStatus.rejected => Colors.red.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

/// App-bar button for the admin dashboard: opens the dealers list and badges
/// the number of applications waiting for review.
class DealersButton extends StatefulWidget {
  const DealersButton({super.key, this.service});

  final DealerAdminService? service;

  @override
  State<DealersButton> createState() => _DealersButtonState();
}

class _DealersButtonState extends State<DealersButton> {
  late final DealerAdminService _service =
      widget.service ?? DealerAdminService();
  late final Stream<List<DealerAccount>> _dealers = _service.watchDealers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DealerAccount>>(
      stream: _dealers,
      builder: (context, snapshot) {
        final pending = (snapshot.data ?? const <DealerAccount>[])
            .where((d) => d.isPending)
            .length;
        return AdminBarButton(
          icon: Icons.handshake_outlined,
          label: 'Dealers',
          badgeCount: pending,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DealersScreen(service: _service),
          )),
        );
      },
    );
  }
}
