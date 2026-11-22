import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_strings.dart';
import '../../models/dealer_account.dart';
import '../../services/account_exception.dart';
import '../../services/account_service.dart';
import '../../services/dealer_auth_service.dart';
import '../../services/launchers.dart';
import '../../theme/app_palette.dart';
import '../../widgets/account_field.dart';
import '../../widgets/cassia_header.dart';
import '../../widgets/cassia_ui.dart';

/// The dealer side: sign in or apply for a dealership, and — once signed in —
/// the dealer's dashboard with their ledger, tier and awards (all read-only,
/// set by the company). Reached from the "Dealership" card on Home.
class DealerPortalScreen extends StatelessWidget {
  const DealerPortalScreen({super.key, this.service});

  /// Replaceable in tests; defaults to a Firebase-backed service.
  final DealerAuthService? service;

  @override
  Widget build(BuildContext context) {
    final auth = service ?? DealerAuthService();
    return Scaffold(
      appBar: CassiaHeader(onBack: () => Navigator.of(context).maybePop()),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (CassiaAccounts.roleOf(user) == AccountRole.dealer) {
            return _DealerDashboard(uid: user!.uid, service: auth);
          }
          return _DealerForms(service: auth);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- forms

class _DealerForms extends StatefulWidget {
  const _DealerForms({required this.service});

  final DealerAuthService service;

  @override
  State<_DealerForms> createState() => _DealerFormsState();
}

class _DealerFormsState extends State<_DealerForms> {
  int _tab = 0; // 0 sign in, 1 apply
  int _step = 0; // apply step (0 or 1)
  bool _busy = false;
  String? _error;

  final _inPhone = TextEditingController();
  final _inPass = TextEditingController();

  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _business = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _products = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _inPhone,
      _inPass,
      _owner,
      _phone,
      _pass,
      _pass2,
      _business,
      _city,
      _district,
      _address,
      _products,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchTab(int tab) {
    setState(() {
      _tab = tab;
      _step = 0;
      _error = null;
    });
  }

  String _message(AccountError e, {required bool signUp}) {
    final s = context.s;
    return switch (e) {
      AccountError.alreadyExists => s.accountExistsError,
      AccountError.wrongCredentials => s.wrongMobileOrPassword,
      AccountError.network => s.noConnectionBody,
      AccountError.other => s.somethingWentWrong,
    };
  }

  Future<void> _signIn() async {
    final s = context.s;
    if (!CassiaAccounts.isValidMobile(_inPhone.text)) {
      setState(() => _error = s.enterValidMobile);
      return;
    }
    if (_inPass.text.isEmpty) {
      setState(() => _error = s.somethingWentWrong);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.login(phone: _inPhone.text, password: _inPass.text);
      // The StreamBuilder in DealerPortalScreen swaps to the dashboard.
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = _message(e.error, signUp: false));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateStep1() {
    final s = context.s;
    if (_owner.text.trim().isEmpty) return s.enterYourName;
    if (!CassiaAccounts.isValidMobile(_phone.text)) return s.enterValidMobile;
    if (_pass.text.length < 8) return s.passwordTooShort;
    if (_pass2.text != _pass.text) return s.passwordsDontMatch;
    return null;
  }

  Future<void> _continueApply() async {
    final problem = _validateStep1();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _step = 1;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final s = context.s;
    if (_business.text.trim().isEmpty) {
      setState(() => _error = s.somethingWentWrong);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.apply(
        ownerName: _owner.text.trim(),
        phone: _phone.text,
        password: _pass.text,
        businessName: _business.text.trim(),
        city: _city.text.trim(),
        district: _district.text.trim(),
        shopAddress: _address.text.trim(),
        products: _products.text.trim(),
        notes: _notes.text.trim(),
      );
      // On success the StreamBuilder swaps to the dashboard (pending state).
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          _error = _message(e.error, signUp: true);
          if (e.error == AccountError.alreadyExists) _step = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final under = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, under + 24),
      children: [
        AccountHero(
          kicker: s.dealerPortal,
          title: s.cassiaDealership,
          subtitle: s.dealershipTagline,
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(22)),
            border: Border.all(color: c.line),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            children: [
              AccountTabs(
                tabs: [s.signInLabel, s.applyAsDealer],
                index: _tab,
                onChanged: _switchTab,
              ),
              const SizedBox(height: 20),
              if (_tab == 0) _signInForm(s) else _applyForm(s),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorText(_error!),
              ],
            ],
          ),
        ),
        AccountFootnote(
          text: s.secureAccessDealers,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _signInForm(AppStrings s) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.welcomeBack,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 4),
        Text(s.signInDealerAccount,
            style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: 18),
        AccountField(
          label: s.mobileNumber,
          controller: _inPhone,
          hint: s.mobileHint,
          leading: '📱',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AccountField(
          label: s.password,
          controller: _inPass,
          hint: s.yourPassword,
          leading: '🔒',
          obscure: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _busy ? null : _signIn,
        ),
        const SizedBox(height: 20),
        _busy
            ? const _Spinner()
            : BlockButton(label: s.signInLabel, onTap: _signIn),
        const SizedBox(height: 14),
        Center(
          child: _LinkText(
            lead: s.notDealerYet,
            action: s.applyNow,
            onTap: () => _switchTab(1),
          ),
        ),
      ],
    );
  }

  Widget _applyForm(AppStrings s) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.createYourAccount,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 4),
        Text(_step == 0 ? s.dealerStep1 : s.dealerStep2,
            style: TextStyle(color: c.muted, fontSize: 13)),
        const SizedBox(height: 18),
        if (_step == 0) ...[
          AccountField(
              label: s.ownerName,
              controller: _owner,
              hint: s.fullName,
              leading: '👤'),
          const SizedBox(height: 14),
          AccountField(
              label: s.mobileNumber,
              controller: _phone,
              hint: s.mobileHint,
              leading: '📱',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          AccountField(
              label: s.password,
              controller: _pass,
              hint: s.atLeast8,
              leading: '🔒',
              obscure: true),
          const SizedBox(height: 14),
          AccountField(
              label: s.confirmPassword,
              controller: _pass2,
              hint: s.repeatPassword,
              leading: '🔒',
              obscure: true),
          const SizedBox(height: 20),
          BlockButton(label: s.continueLabel, onTap: _continueApply),
        ] else ...[
          AccountField(
              label: s.businessName, controller: _business, leading: '🏪'),
          const SizedBox(height: 14),
          AccountField(label: s.city, controller: _city, leading: '🏙️'),
          const SizedBox(height: 14),
          AccountField(
              label: s.districtLabel, controller: _district, leading: '📍'),
          const SizedBox(height: 14),
          AccountField(
              label: s.shopAddress,
              controller: _address,
              leading: '🧭',
              maxLines: 2),
          const SizedBox(height: 14),
          AccountField(
              label: s.productsYouSell,
              controller: _products,
              leading: '🌱',
              maxLines: 2),
          const SizedBox(height: 14),
          AccountField(
              label: s.notesOptional,
              controller: _notes,
              leading: '📝',
              maxLines: 2),
          const SizedBox(height: 20),
          _busy
              ? const _Spinner()
              : BlockButton(label: s.submitApplication, onTap: _submit),
          const SizedBox(height: 10),
          BlockButton(
            label: s.back,
            outlined: true,
            onTap: () => setState(() {
              _step = 0;
              _error = null;
            }),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: _LinkText(
            lead: s.alreadyDealer,
            action: s.signInLabel,
            onTap: () => _switchTab(0),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- dashboard

class _DealerDashboard extends StatelessWidget {
  const _DealerDashboard({required this.uid, required this.service});

  final String uid;
  final DealerAuthService service;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final under = MediaQuery.paddingOf(context).bottom;

    return StreamBuilder<DealerAccount?>(
      stream: service.watchAccount(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState != ConnectionState.active) {
          return const _Spinner();
        }
        final account = snapshot.data;
        final user = FirebaseAuth.instance.currentUser;
        final name = account?.ownerName.isNotEmpty == true
            ? account!.ownerName
            : (user?.displayName ?? s.cassiaDealership);

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, under + 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B2318), Color(0xFF3C3220)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  if (account?.businessName.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(account!.businessName,
                        style: const TextStyle(
                            color: Color(0xDDFFFFFF), fontSize: 13)),
                  ],
                  const SizedBox(height: 10),
                  if (account != null) _StatusPill(status: account.status),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (account == null)
              const _Spinner()
            else if (account.isPending)
              _notice(context, '⏳', s.applicationPending)
            else if (account.status == DealerStatus.rejected)
              _notice(context, '⚠️', s.applicationRejected)
            else
              ..._ledger(context, s, account),
            const SizedBox(height: 26),
            BlockButton(
              label: s.signOut,
              outlined: true,
              onTap: () async {
                await service.signOut();
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                  showToast(context, s.signedOut);
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _ledger(BuildContext context, AppStrings s, DealerAccount a) {
    final rupees = _money(a.outstandingBalance);
    final purchases = _money(a.totalPurchases);
    return [
      Row(
        children: [
          Expanded(
            child: _StatCard(
              label: s.outstandingBalance,
              value: a.outstandingBalance == 0 ? '—' : rupees,
              emoji: '💰',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: s.totalPurchases,
              value: a.totalPurchases == 0 ? '—' : purchases,
              emoji: '📦',
            ),
          ),
        ],
      ),
      if (a.tier.isNotEmpty) ...[
        const SizedBox(height: 14),
        _chipCard(context, s.tierLabel, [a.tier]),
      ],
      if (a.awards.isNotEmpty) ...[
        const SizedBox(height: 14),
        _chipCard(context, s.awardsLabel, a.awards),
      ],
      if (a.perks.isNotEmpty) ...[
        const SizedBox(height: 14),
        _chipCard(context, s.perksLabel, a.perks),
      ],
      const SizedBox(height: 18),
      BlockButton(
        label: s.requestStatement,
        onTap: () => Launchers.sendOnWhatsApp(
          'Assalam-o-Alaikum! I am a Cassia dealer'
          '${a.businessName.isNotEmpty ? ' (${a.businessName})' : ''}'
          '. Please share my latest account statement.',
        ),
      ),
    ];
  }

  Widget _notice(BuildContext context, String emoji, String text) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _chipCard(BuildContext context, String title, List<String> items) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: c.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.line),
                  ),
                  child: Text('🏅 $item',
                      style: TextStyle(
                          color: c.ink, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Rupees with thousands separators. Prices are otherwise never shown in the
  /// app, but a dealer's own ledger is money the company told them directly.
  static String _money(num value) {
    final whole = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return 'Rs $buf';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final DealerStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, label) = switch (status) {
      DealerStatus.approved => (const Color(0xFF2F7A3F), 'Approved'),
      DealerStatus.pending => (const Color(0xFFB8860B), 'Pending'),
      DealerStatus.rejected => (const Color(0xFF9B3B2E), 'Not approved'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.emoji});

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: c.ink, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- small bits

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: context.colors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: context.colors.danger, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(
      {required this.lead, required this.action, required this.onTap});

  final String lead;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '$lead ', style: TextStyle(color: c.muted, fontSize: 13)),
            TextSpan(
              text: action,
              style: TextStyle(
                  color: c.green, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
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
