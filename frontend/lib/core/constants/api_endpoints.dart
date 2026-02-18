class ApiEndpoints {
  ApiEndpoints._();

  // Base URL — when served from the same Go server, use relative path.
  // Override via --dart-define=API_BASE_URL=... for separate deployments.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api/v1',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
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
