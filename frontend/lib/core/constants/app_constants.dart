class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Make It Exist';
  static const String appTagline = 'If it can be imagined, we\'ll Make It Exist.';
  static const String appVersion = '1.0.0';

  // AIM
  static const String aimEmailDomain = 'aim.edu';
  static const String aimName = 'AIM';

  // Build Schedule
  static const int buildHoursPerDay = 8;
  static const List<String> buildDays = ['Saturday', 'Sunday'];

  // Pricing (INR)
  static const Map<String, double> basePricing = {
    'basic': 2999.0,
    'standard': 5999.0,
    'advanced': 11999.0,
  };
  static const double mobileAppMultiplier = 1.5;
  static const double whitelabelSurcharge = 1999.0;

  // Free Hosting Options
  static const List<String> freeHostingOptions = [
    'Vercel',
    'Replit',
    'Heroku',
  ];

  // Request Types
  static const String typeWebsite = 'website';
  static const String typeMobileApp = 'mobile_app';
  static const String typeBoth = 'both';

  // Pagination
  static const int defaultPageSize = 20;
}
