import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_strings.dart';
import '../../models/farmer_profile.dart';
import '../../services/account_exception.dart';
import '../../services/account_service.dart';
import '../../services/farmer_auth_service.dart';
import '../../theme/app_palette.dart';
import '../../widgets/account_field.dart';
import '../../widgets/cassia_header.dart';
import '../../widgets/cassia_ui.dart';
import '../../widgets/district_picker.dart';

/// A crop a farmer can pick while registering. Stored by its English name.
typedef _Crop = ({String emoji, String en, String ur});

const List<_Crop> _cropChoices = [
  (emoji: '🍅', en: 'Tomato', ur: 'ٹماٹر'),
  (emoji: '🌶️', en: 'Chilli', ur: 'مرچ'),
  (emoji: '🌿', en: 'Okra', ur: 'بھنڈی'),
  (emoji: '🥒', en: 'Cucumber', ur: 'کھیرا'),
  (emoji: '🍆', en: 'Brinjal', ur: 'بینگن'),
  (emoji: '🥬', en: 'Gourds', ur: 'کدو'),
  (emoji: '🫛', en: 'Peas', ur: 'مٹر'),
  (emoji: '🌾', en: 'Paddy', ur: 'دھان'),
  (emoji: '🥕', en: 'Carrot', ur: 'گاجر'),
  (emoji: '🧅', en: 'Onion', ur: 'پیاز'),
  (emoji: '🌱', en: 'Wheat', ur: 'گندم'),
  (emoji: '🧺', en: 'Cotton', ur: 'کپاس'),
];

/// The farmer's door: login with a mobile number and secret number (PIN), a
/// step-by-step register, and — once signed in — their own account page.
class FarmerAuthScreen extends StatelessWidget {
  const FarmerAuthScreen({super.key, this.service});

  /// Replaceable in tests; defaults to a Firebase-backed service.
  final FarmerAuthService? service;

  @override
  Widget build(BuildContext context) {
    final auth = service ?? FarmerAuthService();
    return Scaffold(
      appBar: CassiaHeader(onBack: () => Navigator.of(context).maybePop()),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (CassiaAccounts.roleOf(user) == AccountRole.farmer) {
            return _FarmerAccountView(uid: user!.uid, service: auth);
          }
          return _FarmerForms(service: auth);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- forms

class _FarmerForms extends StatefulWidget {
  const _FarmerForms({required this.service});

  final FarmerAuthService service;

  @override
  State<_FarmerForms> createState() => _FarmerFormsState();
}

class _FarmerFormsState extends State<_FarmerForms> {
  int _tab = 0; // 0 login, 1 register
  int _step = 0; // register step
  bool _busy = false;
  String? _error;

  final _loginPhone = TextEditingController();
  final _loginPin = TextEditingController();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _town = TextEditingController();
  final _village = TextEditingController();
  final _crops = <String>{};

  /// Chosen from the shared district list (not typed), so it matches a
  /// dealer's district exactly when the farmer searches in Find a Dealer.
  String _district = '';

  static const _steps = 8;

  @override
  void dispose() {
    for (final c in [
      _loginPhone,
      _loginPin,
      _name,
      _phone,
      _pin,
      _pin2,
      _town,
      _village,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchTab(int tab) {
    setState(() {
      _tab = tab;
      _error = null;
      _step = 0;
    });
  }

  String _message(AccountError e, {required bool signUp}) {
    final s = context.s;
    return switch (e) {
      AccountError.alreadyExists => s.accountExistsError,
      AccountError.wrongCredentials => s.wrongMobileOrPin,
      AccountError.network => s.noConnectionBody,
      AccountError.other => s.somethingWentWrong,
    };
  }

  Future<void> _login() async {
    final s = context.s;
    if (!CassiaAccounts.isValidMobile(_loginPhone.text)) {
      setState(() => _error = s.enterValidMobile);
      return;
    }
    if (_loginPin.text.trim().length < 6) {
      setState(() => _error = s.pinMustBe6);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service
          .login(phone: _loginPhone.text, pin: _loginPin.text.trim());
      if (mounted) _done(s.welcomeReady);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = _message(e.error, signUp: false));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Checks the current register step; returns an error message or null.
  String? _validateStep() {
    final s = context.s;
    switch (_step) {
      case 0:
        if (_name.text.trim().isEmpty) return s.enterYourName;
      case 1:
        if (!CassiaAccounts.isValidMobile(_phone.text)) {
          return s.enterValidMobile;
        }
      case 2:
        if (!RegExp(r'^\d{6}$').hasMatch(_pin.text.trim())) {
          return s.pinMustBe6;
        }
      case 3:
        if (_pin2.text.trim() != _pin.text.trim()) return s.pinsDontMatch;
      case 4:
        if (_district.isEmpty) return s.chooseDistrictError;
      case 5:
        if (_town.text.trim().isEmpty) return s.enterCityTown;
      case 7:
        if (_crops.isEmpty) return s.pickAtLeastOneCrop;
    }
    return null;
  }

  Future<void> _next() async {
    final problem = _validateStep();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_step < _steps - 1) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    await _register();
  }

  Future<void> _register() async {
    final s = context.s;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.register(
        name: _name.text.trim(),
        phone: _phone.text,
        pin: _pin.text.trim(),
        district: _district,
        town: _town.text.trim(),
        village: _village.text.trim(),
        crops: _crops.toList(),
      );
      if (mounted) _done(s.welcomeReady);
    } on AccountException catch (e) {
      if (mounted) {
        setState(() {
          _error = _message(e.error, signUp: true);
          // Send them back to the mobile step to change a taken number.
          if (e.error == AccountError.alreadyExists) _step = 1;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done(String message) {
    Navigator.of(context).maybePop();
    showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final under = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 14, 16, under + 24),
      children: [
        AccountHero(
          kicker: s.forFarmers,
          title: s.growWithCassiaTitle,
          subtitle: s.heroTagline,
        ),
        Container(
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(22)),
            border: Border.all(color: context.colors.line),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            children: [
              AccountTabs(
                tabs: [s.loginLabel, s.registerLabel],
                index: _tab,
                onChanged: _switchTab,
              ),
              const SizedBox(height: 20),
              if (_tab == 0) _loginForm(s) else _registerStep(s),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorText(_error!),
              ],
            ],
          ),
        ),
        AccountFootnote(text: s.accountProtectedPin),
      ],
    );
  }

  Widget _loginForm(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.welcomeBack,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.ink)),
        const SizedBox(height: 4),
        Text(s.loginFarmerHint,
            style: TextStyle(color: context.colors.muted, fontSize: 13)),
        const SizedBox(height: 18),
        AccountField(
          label: s.mobileNumber,
          controller: _loginPhone,
          hint: s.mobileHint,
          leading: '📱',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        AccountField(
          label: s.secretNumberPin,
          controller: _loginPin,
          hint: s.sixNumbers,
          leading: '🔒',
          keyboardType: TextInputType.number,
          obscure: true,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: _busy ? null : _login,
        ),
        const SizedBox(height: 20),
        _busy
            ? const _Spinner()
            : BlockButton(label: s.loginLabel, onTap: _login),
        const SizedBox(height: 14),
        Center(
          child: _LinkText(
            lead: s.newFarmer,
            action: s.registerLabel,
            onTap: () => _switchTab(1),
          ),
        ),
      ],
    );
  }

  Widget _registerStep(AppStrings s) {
    final rtl = s.isRtl;
    final titles = [
      s.whatIsYourName,
      s.whatIsYourMobile,
      s.choosePin,
      s.confirmPin,
      s.whichDistrict,
      s.whichTown,
      s.whichVillage,
      s.whichCrops,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Progress(step: _step, total: _steps),
        const SizedBox(height: 18),
        Text(titles[_step],
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.ink)),
        const SizedBox(height: 14),
        _stepField(s, rtl),
        const SizedBox(height: 22),
        _busy
            ? const _Spinner()
            : BlockButton(
                label: _step == _steps - 1 ? s.createAccount : s.nextLabel,
                onTap: _next,
              ),
        if (_step > 0) ...[
          const SizedBox(height: 10),
          BlockButton(
            label: s.back,
            outlined: true,
            onTap: () => setState(() {
              _step--;
              _error = null;
            }),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: _LinkText(
            lead: s.alreadyRegistered,
            action: s.loginLabel,
            onTap: () => _switchTab(0),
          ),
        ),
      ],
    );
  }

  Widget _stepField(AppStrings s, bool rtl) {
    switch (_step) {
      case 0:
        return _labelled(
          s.requiredLabel,
          AccountField(
            label: s.fullName,
            controller: _name,
            hint: s.exampleName,
            leading: '👤',
            textInputAction: TextInputAction.next,
            autofocus: true,
          ),
        );
      case 1:
        return _labelled(
          s.requiredLabel,
          AccountField(
            label: s.mobileNumber,
            controller: _phone,
            hint: s.mobileHint,
            leading: '📱',
            keyboardType: TextInputType.phone,
          ),
        );
      case 2:
        return _labelled(
          s.requiredLabel,
          AccountField(
            label: s.secretNumberPin,
            controller: _pin,
            hint: s.sixNumbers,
            leading: '🔒',
            keyboardType: TextInputType.number,
            obscure: true,
            maxLength: 6,
          ),
        );
      case 3:
        return _labelled(
          s.requiredLabel,
          AccountField(
            label: s.confirmPin,
            controller: _pin2,
            hint: s.sixNumbers,
            leading: '🔒',
            keyboardType: TextInputType.number,
            obscure: true,
            maxLength: 6,
          ),
        );
      case 4:
        return _labelled(
          s.requiredLabel,
          DistrictPickerField(
            value: _district,
            onChanged: (v) => setState(() {
              _district = v;
              _error = null;
            }),
          ),
        );
      case 5:
        return _labelled(
          s.requiredLabel,
          AccountField(
            label: s.cityTown,
            controller: _town,
            hint: s.cityTownHint,
            leading: '🏙️',
          ),
        );
      case 6:
        return _labelled(
          s.optionalLabel,
          AccountField(
            label: s.myVillage,
            controller: _village,
            leading: '🏡',
          ),
        );
      case 7:
      default:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final crop in _cropChoices)
              _CropChip(
                label: '${crop.emoji} ${rtl ? crop.ur : crop.en}',
                selected: _crops.contains(crop.en),
                onTap: () => setState(() {
                  _crops.contains(crop.en)
                      ? _crops.remove(crop.en)
                      : _crops.add(crop.en);
                  _error = null;
                }),
              ),
          ],
        );
    }
  }

  Widget _labelled(String tag, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tag,
            style: TextStyle(
                color: context.colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

// --------------------------------------------------------- account view

class _FarmerAccountView extends StatelessWidget {
  const _FarmerAccountView({required this.uid, required this.service});

  final String uid;
  final FarmerAuthService service;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final under = MediaQuery.paddingOf(context).bottom;

    return StreamBuilder<FarmerProfile?>(
      stream: service.watchProfile(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final user = FirebaseAuth.instance.currentUser;
        final name = profile?.name.isNotEmpty == true
            ? profile!.name
            : (user?.displayName ?? '');
        final phone = profile?.phone ??
            (user?.email?.split('@').first ?? '');

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
                  colors: [Color(0xFF123E22), Color(0xFF1F5A30)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text('🧑‍🌾', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 8),
                  Text(
                    name.isEmpty ? s.myFarmerAccount : name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('📱 ${s.data(phone)}',
                        style: const TextStyle(
                            color: Color(0xDDFFFFFF), fontSize: 13)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            if ((profile?.district ?? '').isNotEmpty)
              _infoRow(context, '📍', s.myDistrict, profile!.district),
            if ((profile?.town ?? '').isNotEmpty)
              _infoRow(context, '🏙️', s.cityTown, profile!.town),
            if ((profile?.village ?? '').isNotEmpty)
              _infoRow(context, '🏡', s.myVillage, profile!.village),
            if (profile != null && profile.crops.isNotEmpty) ...[
              const SizedBox(height: 10),
              SectionTitle(s.myCrops),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final crop in profile.crops)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: c.line),
                      ),
                      child: Text(crop,
                          style: TextStyle(
                              color: c.ink, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
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

  Widget _infoRow(
      BuildContext context, String emoji, String label, String value) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(color: c.muted, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style:
                      TextStyle(color: c.ink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- small bits

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= step ? c.gold : c.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _CropChip extends StatelessWidget {
  const _CropChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c.green : c.background,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? c.green : c.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : c.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.symmetric(vertical: 8),
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
