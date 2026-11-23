import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/dealer_listing.dart';
import '../services/account_service.dart';
import '../services/farmer_auth_service.dart';
import '../services/find_dealer_service.dart';
import '../services/launchers.dart';
import '../theme/app_palette.dart';
import '../widgets/account_field.dart';
import '../widgets/cassia_header.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/district_picker.dart';
import 'account/farmer_auth_screen.dart';

/// "Find a Dealer": shows the signed-in farmer the seed dealers closest to
/// them — the dealers in their own district, with those in the same town
/// first. Reached from the 📍 tile on Home.
///
/// A farmer must be signed in (so we know their district and town, and so they
/// may read the public dealer directory). A farmer who registered before these
/// fields existed can set their area here; it is saved back to their profile.
class FindDealerScreen extends StatelessWidget {
  const FindDealerScreen({super.key, this.farmerService, this.finder});

  /// Replaceable in tests; default to Firebase-backed services.
  final FarmerAuthService? farmerService;
  final FindDealerService? finder;

  @override
  Widget build(BuildContext context) {
    final farmer = farmerService ?? FarmerAuthService();
    final find = finder ?? FindDealerService();
    return Scaffold(
      appBar: CassiaHeader(onBack: () => Navigator.of(context).maybePop()),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (CassiaAccounts.roleOf(user) == AccountRole.farmer) {
            return _FarmerFinder(uid: user!.uid, farmer: farmer, finder: find);
          }
          return const _LoginPrompt();
        },
      ),
    );
  }
}

// --------------------------------------------------------------- header

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123E22), Color(0xFF1F5A30)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(
            s.findDealer,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            s.findDealerSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- login gate

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final under = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, under + 24),
      children: [
        const _Hero(),
        const SizedBox(height: 18),
        _InfoCard(
          emoji: '🔒',
          title: s.loginToFindDealersTitle,
          body: s.loginToFindDealersBody,
        ),
        const SizedBox(height: 16),
        BlockButton(
          label: s.farmerLoginLabel,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FarmerAuthScreen()),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------- farmer view

class _FarmerFinder extends StatefulWidget {
  const _FarmerFinder(
      {required this.uid, required this.farmer, required this.finder});

  final String uid;
  final FarmerAuthService farmer;
  final FindDealerService finder;

  @override
  State<_FarmerFinder> createState() => _FarmerFinderState();
}

class _FarmerFinderState extends State<_FarmerFinder> {
  bool _loading = true;
  String _district = '';
  String _town = '';
  Future<List<DealerListing>>? _results;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.farmer.loadProfile(widget.uid);
      if (!mounted) return;
      setState(() {
        _district = profile?.district ?? '';
        _town = profile?.town ?? '';
        _loading = false;
        if (_district.isNotEmpty) _search();
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search() {
    _results = widget.finder.nearby(district: _district, town: _town);
  }

  Future<void> _changeLocation() async {
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LocationSheet(district: _district, town: _town),
    );
    if (picked == null) return;
    setState(() {
      _district = picked.$1;
      _town = picked.$2;
      _search();
    });
    try {
      await widget.farmer.updateLocation(
          uid: widget.uid, district: _district, town: _town);
    } catch (_) {
      // The search still runs with the new area even if the save fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final under = MediaQuery.paddingOf(context).bottom;
    if (_loading) return const _Spinner();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, under + 24),
      children: [
        const _Hero(),
        const SizedBox(height: 16),
        if (_district.isEmpty)
          _InfoCard(
            emoji: '📍',
            title: s.setYourAreaTitle,
            body: s.setYourAreaBody,
            action: s.setYourArea,
            onAction: _changeLocation,
          )
        else ...[
          _locationBar(context, s),
          const SizedBox(height: 16),
          _resultsSection(context, s),
        ],
      ],
    );
  }

  Widget _locationBar(BuildContext context, AppStrings s) {
    final c = context.colors;
    final where =
        _town.isEmpty ? s.data(_district) : '${s.data(_town)} · ${s.data(_district)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.yourAreaLabel,
                    style: TextStyle(color: c.muted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(where,
                    style: TextStyle(
                        color: c.ink, fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          TextButton(
            onPressed: _changeLocation,
            style: TextButton.styleFrom(
                foregroundColor: c.green,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero),
            child: Text(s.change,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(BuildContext context, AppStrings s) {
    return FutureBuilder<List<DealerListing>>(
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Spinner();
        }
        if (snap.hasError) {
          return _InfoCard(
            emoji: '⚠️',
            title: s.somethingWentWrong,
            body: s.couldNotLoadDealers,
            action: s.tryAgain,
            onAction: () => setState(_search),
          );
        }
        final dealers = snap.data ?? const <DealerListing>[];
        if (dealers.isEmpty) {
          return _InfoCard(
            emoji: '🔍',
            title: s.noDealersNearbyTitle,
            body: s.noDealersNearbyBody(_district),
            action: s.askOurTeam,
            onAction: () => Launchers.whatsAppEnquiry(),
          );
        }
        final wantedTown = DealerListing.normalizePlace(_town);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(s.dealersNearYou),
            for (final d in dealers) ...[
              _DealerCard(
                dealer: d,
                sameTown: wantedTown.isNotEmpty &&
                    DealerListing.normalizePlace(d.town) == wantedTown,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------- dealer card

class _DealerCard extends StatelessWidget {
  const _DealerCard({required this.dealer, required this.sameTown});

  final DealerListing dealer;
  final bool sameTown;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final place = dealer.town.isEmpty
        ? s.data(dealer.district)
        : '${s.data(dealer.town)} · ${s.data(dealer.district)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sameTown ? c.green : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏪', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.data(dealer.displayName),
                        style: TextStyle(
                            color: c.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    if (dealer.ownerName.isNotEmpty &&
                        dealer.businessName.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(s.data(dealer.ownerName),
                          style: TextStyle(color: c.muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (sameTown)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.green,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(s.yourTownBadge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _line(c, '📍', place),
          if (dealer.shopAddress.isNotEmpty) ...[
            const SizedBox(height: 5),
            _line(c, '🧭', s.data(dealer.shopAddress)),
          ],
          if (dealer.products.isNotEmpty) ...[
            const SizedBox(height: 5),
            _line(c, '🌱', s.data(dealer.products)),
          ],
          if (dealer.phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: BlockButton(
                    label: '📞 ${s.callLabel}',
                    onTap: () => Launchers.dialPhone(dealer.phone),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BlockButton(
                    label: '💬 ${s.whatsAppLabel}',
                    outlined: true,
                    onTap: () => Launchers.whatsAppTo(
                        dealer.phone, s.dealerWhatsAppIntro),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(dynamic c, String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(color: c.ink, fontSize: 13, height: 1.35)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------- location sheet

/// A bottom sheet to choose a district and type a town, returned as
/// `(district, town)`. Used to set or change the farmer's area.
class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.district, required this.town});

  final String district;
  final String town;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late String _district = widget.district;
  late final TextEditingController _town =
      TextEditingController(text: widget.town);
  String? _error;

  @override
  void dispose() {
    _town.dispose();
    super.dispose();
  }

  void _save() {
    final s = context.s;
    if (_district.isEmpty) {
      setState(() => _error = s.chooseDistrictError);
      return;
    }
    if (_town.text.trim().isEmpty) {
      setState(() => _error = s.enterCityTown);
      return;
    }
    Navigator.of(context).pop((_district, _town.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final under = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + under),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.setYourAreaTitle,
                style: TextStyle(
                    color: c.ink, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(s.setYourAreaBody,
                style: TextStyle(color: c.muted, fontSize: 13)),
            const SizedBox(height: 18),
            DistrictPickerField(
              value: _district,
              onChanged: (v) => setState(() {
                _district = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 14),
            AccountField(
              label: s.cityTown,
              controller: _town,
              hint: s.cityTownHint,
              leading: '🏙️',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: c.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: c.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            BlockButton(label: s.saveLabel, onTap: _save),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ small bits

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.emoji,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: c.ink, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 13, height: 1.4)),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 16),
            BlockButton(label: action!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}
