import 'package:material_ui/material_ui.dart';

import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../services/launchers.dart';
import '../state/app_settings.dart';
import '../theme/app_palette.dart';
import '../widgets/cassia_ui.dart';

/// Settings (language, light/dark) plus company info and contact. Company
/// details come from [AppConfig] so they are never hard-coded per screen.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final settings = AppSettingsScope.maybeOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.supportAndAbout)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // --- Company card ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                const CassiaLogo(height: 56),
                const SizedBox(height: 10),
                Text(AppConfig.companyName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.green)),
                const SizedBox(height: 4),
                Text(s.motto, style: TextStyle(color: c.muted)),
              ],
            ),
          ),
          const SizedBox(height: 22),

          if (settings != null) ...[
            _section(context, s.settings),
            _settingsCard(context, settings),
            const SizedBox(height: 14),
          ],

          _section(context, s.contact),
          _tile(
            context,
            icon: Icons.chat,
            title: s.whatsApp,
            subtitle: AppConfig.phone,
            onTap: Launchers.whatsAppEnquiry,
          ),
          _tile(
            context,
            icon: Icons.call,
            title: s.call,
            subtitle: AppConfig.phone,
            onTap: () => Launchers.dialPhone(AppConfig.phone),
          ),
          _tile(
            context,
            icon: Icons.call_outlined,
            title: s.landline,
            subtitle: AppConfig.landline,
            onTap: () => Launchers.dialPhone(AppConfig.landline),
          ),
          _tile(
            context,
            icon: Icons.email_outlined,
            title: s.email,
            subtitle: AppConfig.email,
            onTap: () => Launchers.sendEmail(AppConfig.email),
          ),

          const SizedBox(height: 14),
          _section(context, s.online),
          _tile(
            context,
            icon: Icons.language,
            title: s.website,
            subtitle: AppConfig.website,
            onTap: () => Launchers.openWebsite(AppConfig.website),
          ),
          _tile(
            context,
            icon: Icons.facebook,
            title: s.facebook,
            subtitle: s.followUs,
            onTap: () => Launchers.openWebsite(AppConfig.facebook),
          ),
          _tile(
            context,
            icon: Icons.camera_alt_outlined,
            title: s.instagram,
            subtitle: s.followUs,
            onTap: () => Launchers.openWebsite(AppConfig.instagram),
          ),

          const SizedBox(height: 14),
          _section(context, s.address),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: c.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppConfig.address,
                      style: TextStyle(color: c.ink, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Language and light/dark choices. Both apply at once and are remembered.
  Widget _settingsCard(BuildContext context, AppSettings settings) {
    final c = context.colors;
    final s = context.s;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _settingLabel(context, Icons.language, s.language),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            showSelectedIcon: false,
            // Each language is named in itself, so it can always be found.
            segments: const [
              ButtonSegment(value: AppLanguage.en, label: Text('English')),
              ButtonSegment(value: AppLanguage.ur, label: Text('اردو')),
            ],
            selected: {settings.language},
            onSelectionChanged: (choice) => settings.setLanguage(choice.first),
          ),
          const SizedBox(height: 18),
          _settingLabel(context, Icons.brightness_6_outlined, s.appearance),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: ThemeMode.system, label: Text(s.themeSystem)),
              ButtonSegment(value: ThemeMode.light, label: Text(s.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(s.themeDark)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (choice) =>
                settings.setThemeMode(choice.first),
          ),
        ],
      ),
    );
  }

  Widget _settingLabel(BuildContext context, IconData icon, String text) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.green),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
      ],
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 6, 0, 8),
        child: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: context.colors.ink)),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.green.withValues(alpha: 0.12),
          child: Icon(icon, color: c.green, size: 20),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w600, color: c.ink)),
        // Phone numbers, links and emails keep reading left to right in Urdu.
        subtitle: Text(context.s.data(subtitle),
            style: TextStyle(color: c.muted, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: c.muted),
        onTap: onTap,
      ),
    );
  }
}
