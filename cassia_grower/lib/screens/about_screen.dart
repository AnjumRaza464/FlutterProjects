import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../services/launchers.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/cassia_ui.dart';

/// The "About Us" screen, opened from the home quick actions. It tells the
/// company's story — who we are, what we do, our commitment, vision and
/// mission, and how Cassia Seed grew — in the farmer's own language. The
/// wording comes from cassiaseed.com and lives in [AppStrings].
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      appBar: AppBar(title: Text(s.aboutUs)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          // --- Header: logo, name, tagline on the brand green ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF143D20), AppColors.greenLight],
              ),
            ),
            child: Column(
              children: [
                const CassiaLogo(height: 54),
                const SizedBox(height: 14),
                Text(
                  AppConfig.companyName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  s.aboutTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xE6FFFFFF), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          // --- Who We Are ---
          SectionTitle(s.aboutWhoTitle),
          _Prose(s.aboutWhoBody),

          // --- What We Do ---
          SectionTitle(s.aboutDoTitle),
          _InfoCard(
              emoji: '🔬',
              title: s.aboutResearchTitle,
              body: s.aboutResearchBody),
          _InfoCard(
              emoji: '🌱',
              title: s.aboutTradingTitle,
              body: s.aboutTradingBody),
          _InfoCard(
              emoji: '📣',
              title: s.aboutMarketingTitle,
              body: s.aboutMarketingBody),

          // --- Our Commitment ---
          SectionTitle(s.aboutCommitmentTitle),
          _Prose(s.aboutCommitmentBody),

          // --- Vision & Mission ---
          SectionTitle(s.aboutVisionTitle),
          _Prose(s.aboutVisionBody),
          SectionTitle(s.aboutMissionTitle),
          _Prose(s.aboutMissionBody),

          // --- Our Story ---
          SectionTitle(s.aboutStoryTitle),
          const _StoryStats(),
          const SizedBox(height: 14),
          _Prose(s.aboutStoryBody1),
          const SizedBox(height: 10),
          _Prose(s.aboutStoryBody2),

          // --- Closing quote ---
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              // A fixed pale wash, the same in both themes.
              gradient: const LinearGradient(
                  colors: [Color(0xFFEAF3E4), Color(0xFFF6ECD0)]),
            ),
            child: Text(
              '“${s.aboutQuote}”',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 20),
          PressButton(
            label: s.aboutVisitWebsite,
            onTap: () => Launchers.openWebsite(AppConfig.website),
          ),
        ],
      ),
    );
  }
}

/// A paragraph of body text with comfortable line height.
class _Prose extends StatelessWidget {
  const _Prose(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: context.colors.ink, fontSize: 14, height: 1.6),
    );
  }
}

/// A raised card with an emoji badge, a title and a short description — used
/// for each of the "What We Do" points.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: raisedBox(context, radius: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF3E4), Color(0xFFF6ECD0)],
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(body,
                    style: TextStyle(color: c.muted, fontSize: 13, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three milestones from the company's story: founded, years, and the
/// year it was incorporated.
class _StoryStats extends StatelessWidget {
  const _StoryStats();

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Row(
      children: [
        Expanded(child: _stat(context, '1985', s.aboutStatFounded)),
        const SizedBox(width: 10),
        Expanded(child: _stat(context, '40+', s.aboutStatYears)),
        const SizedBox(width: 10),
        Expanded(child: _stat(context, '2022', s.aboutStatIncorporated)),
      ],
    );
  }

  Widget _stat(BuildContext context, String big, String label) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: raisedBox(context, radius: 16),
      child: Column(
        children: [
          Text(big,
              style: TextStyle(
                  color: c.green, fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
