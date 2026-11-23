import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Helpers for opening external apps (WhatsApp, phone dialer, web).
///
/// Note: launching WhatsApp only opens the app with a pre-filled draft — the
/// farmer reviews and sends it themselves. The app never sends anything on its
/// own.
class Launchers {
  Launchers._();

  /// Opens a WhatsApp chat with Cassia Seed, pre-filled with [message] (the
  /// cart's order). Returns false if WhatsApp / a browser could not open.
  static Future<bool> sendOnWhatsApp(String message) {
    return _launch(
      'https://wa.me/${AppConfig.whatsappNumber}'
      '?text=${Uri.encodeComponent(message)}',
    );
  }

  /// Opens a WhatsApp chat with a general enquiry (no specific product).
  static Future<bool> whatsAppEnquiry() {
    const message = 'Assalam-o-Alaikum! I have a question about Cassia Seed.';
    return _launch(
      'https://wa.me/${AppConfig.whatsappNumber}'
      '?text=${Uri.encodeComponent(message)}',
    );
  }

  /// Opens a WhatsApp chat with a specific [number] (a dealer), pre-filled
  /// with [message]. The farmer reviews and sends it themselves.
  static Future<bool> whatsAppTo(String number, String message) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return _launch(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );
  }

  static Future<bool> openWebsite(String url) => _launch(url);

  static Future<bool> dialPhone(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    return launchUrl(Uri.parse('tel:$digits'));
  }

  static Future<bool> sendEmail(String address) {
    return launchUrl(Uri(scheme: 'mailto', path: address));
  }

  static Future<bool> _launch(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
