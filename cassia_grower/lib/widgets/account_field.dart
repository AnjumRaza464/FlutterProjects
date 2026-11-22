import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import 'cassia_ui.dart';

/// Shared building blocks for the dealer portal and the farmer login — the
/// green hero card, the Login/Register-style tab switch, the labelled input
/// field, and the footnote under a form — so both read as one design.

/// The green gradient banner at the top of an account screen: the logo, a
/// small kicker ("FOR FARMERS" / "DEALER PORTAL"), a title and a line of help.
class AccountHero extends StatelessWidget {
  const AccountHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final String kicker;
  final String title;
  final String subtitle;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const CassiaLogo(height: 48),
          const SizedBox(height: 12),
          Text(
            kicker,
            style: TextStyle(
              color: const Color(0xFFE2BD62),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: s.spacing(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xDDFFFFFF),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The two-tab switch at the top of a form card (e.g. Login | Register).
class AccountTabs extends StatelessWidget {
  const AccountTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == index
                        ? const [
                            BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 8,
                                offset: Offset(0, 3)),
                          ]
                        : null,
                  ),
                  child: Text(
                    tabs[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == index ? c.green : c.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A labelled input matching the design: a label above a rounded field with a
/// leading emoji and, for secrets, an eye to reveal the text.
class AccountField extends StatefulWidget {
  const AccountField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.leading = '',
    this.keyboardType,
    this.obscure = false,
    this.maxLength,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String leading;
  final TextInputType? keyboardType;
  final bool obscure;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final int maxLines;

  @override
  State<AccountField> createState() => _AccountFieldState();
}

class _AccountFieldState extends State<AccountField> {
  late bool _hidden = widget.obscure;

  @override
  void didUpdateWidget(AccountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A form may swap one AccountField for another at the same position (the
    // register wizard, the dealer apply steps), and Flutter then reuses this
    // State. Re-sync the hidden flag when the field's obscure-ness changes,
    // so an obscure field's state never leaks into a non-obscure multiline
    // field — which would crash with "obscured fields cannot be multiline".
    if (oldWidget.obscure != widget.obscure) _hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: c.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              if (widget.leading.isNotEmpty) ...[
                Text(widget.leading, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  // Gate on widget.obscure too, so a reused State can never
                  // obscure a field that isn't meant to be (see above).
                  obscureText: widget.obscure && _hidden,
                  autofocus: widget.autofocus,
                  maxLength: widget.maxLength,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  textInputAction: widget.textInputAction,
                  onSubmitted:
                      widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
                  style: TextStyle(
                    color: c.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      color: c.muted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.obscure)
                GestureDetector(
                  onTap: () => setState(() => _hidden = !_hidden),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The small padlock line under a form, plus a "Back to farmer app" link for
/// the dealer portal.
class AccountFootnote extends StatelessWidget {
  const AccountFootnote({super.key, required this.text, this.onBack});

  final String text;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 14, color: c.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ),
          ],
        ),
        if (onBack != null) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: onBack,
            child: Text(
              '${s.arrow == '→' ? '←' : '→'} ${s.backToFarmerApp}',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
