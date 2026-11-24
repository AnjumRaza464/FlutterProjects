/// App-wide configuration and company details for Cassia Seed.
///
/// Keeping these in one place means we never hard-code the same value
/// (like the WhatsApp number) in many screens.
class AppConfig {
  // --- Company ---
  static const String companyName = 'Cassia Seed (Pvt) Ltd';
  static const String motto = 'Grow with Cassia';
  static const String address =
      'Office F-201 & 202, 2nd Floor, Gulshan-e-Zealpak Society, '
      'SITE Area, Hyderabad, Sindh, Pakistan';

  // --- Contact ---
  static const String whatsappNumber = '923452692533'; // +92 345 2692533
  static const String phone = '0345-2692533';
  static const String landline = '022-3400398';
  static const String email = 'Info@cassiaseed.com';

  // --- Social / Web ---
  static const String website = 'https://cassiaseed.com';
  static const String facebook = 'https://www.facebook.com/share/14i89msye72/';
  static const String instagram = 'https://www.instagram.com/cassiaseedpvt.ltd';

  // --- Features ---
  /// The AI features (Crop Doctor and Ask Cassia) are not live yet. While
  /// this is true, every entry point to them shows a "coming soon" sheet
  /// instead of opening the feature. Set it to false once the Cloud
  /// Functions are deployed (see functions/SETUP.md) to switch them on.
  static bool aiComingSoon = true;
}
