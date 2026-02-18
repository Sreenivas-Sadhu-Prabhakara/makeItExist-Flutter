class ApiEndpoints {
  ApiEndpoints._();

  // Base URL — injected at build time via --dart-define=API_BASE_URL=...
  // Falls back to localhost for local development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String profile = '/auth/profile';

  // Requests
  static const String requests = '/requests';
  static String requestById(String id) => '/requests/$id';

  // Schedule
  static const String schedule = '/schedule';
  static const String scheduleSlots = '/schedule/slots';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminRequests = '/admin/requests';
  static String adminRequestById(String id) => '/admin/requests/$id';
  static const String adminScheduleGenerate = '/admin/schedule/generate';
}
