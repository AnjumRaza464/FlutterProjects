import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_palette.dart';
import 'cassia_ui.dart';

/// Shows the "coming soon" sheet for an AI feature that is not live yet
/// (Crop Doctor or Ask Cassia). It slides up over the current page, the same
/// way the product sheet does, and closes on OK — so the farmer stays on the
/// tab they were on, rather than opening the feature.
///
/// [emoji] and [title] name the feature: 🩺 Crop Doctor, 💬 Ask Cassia.
Future<void> showAiComingSoon(
  BuildContext context, {
  required String emoji,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x88000000),
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => _AiComingSoonSheet(emoji: emoji, title: title),
  );
}

class _AiComingSoonSheet extends StatelessWidget {
  const _AiComingSoonSheet({required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final media = MediaQuery.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: c.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + media.padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The grab handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // The feature's emoji in a soft tinted disc.
            Center(
              child: Container(
                width: 78,
                height: 78,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [c.background, c.line]
                        : const [Color(0xFFEAF3E4), Color(0xFFF6ECD0)],
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.comingSoon,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              s.aiComingSoonBody(title),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 22),
            BlockButton(label: s.ok, onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
