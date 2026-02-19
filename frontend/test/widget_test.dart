// Smoke tests & data-driven tests for Make It Exist app

import 'package:flutter_test/flutter_test.dart';
import 'package:make_it_exist/core/constants/api_endpoints.dart';
import 'package:make_it_exist/core/constants/app_constants.dart';
import 'package:make_it_exist/data/models/user_model.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_event.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_state.dart';

void main() {
  group('AppConstants', () {
    test('app name and branding', () {
      expect(AppConstants.appName, 'Make It Exist');
      expect(AppConstants.appTagline, contains('Make It Exist'));
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('AIM configuration', () {
      expect(AppConstants.aimEmailDomain, 'aim.edu');
      expect(AppConstants.aimName, 'AIM');
    });

    test('build schedule constants', () {
      expect(AppConstants.buildHoursPerDay, 8);
      expect(AppConstants.buildDays, containsAll(['Saturday', 'Sunday']));
    });

    test('pricing tiers are defined', () {
      expect(AppConstants.basePricing.keys, containsAll(['basic', 'standard', 'advanced']));
      expect(AppConstants.basePricing['basic'], greaterThan(0));
      expect(AppConstants.basePricing['advanced']!, greaterThan(AppConstants.basePricing['basic']!));
    });
  });

  group('ApiEndpoints', () {
    test('base URL defaults to relative path', () {
      expect(ApiEndpoints.baseUrl, contains('/api/v1'));
    });

    test('auth endpoints', () {
      expect(ApiEndpoints.googleLogin, '/auth/google');
      expect(ApiEndpoints.login, '/auth/login');
      expect(ApiEndpoints.profile, '/auth/profile');
    });

    test('request endpoints', () {
      expect(ApiEndpoints.requests, '/requests');
      expect(ApiEndpoints.requestById('abc'), '/requests/abc');
    });

    test('admin endpoints', () {
      expect(ApiEndpoints.adminDashboard, '/admin/dashboard');
      expect(ApiEndpoints.adminUsers, '/admin/users');
      expect(ApiEndpoints.adminResetPassword('xyz'), '/admin/users/xyz/reset-password');
    });
  });

  group('UserModel — Data-Driven', () {
    // Data-driven: various JSON payloads
    final testCases = <Map<String, dynamic>>[
      {
        'name': 'student user',
        'json': {
          'id': 'uuid-1', 'email': 'student@aim.edu', 'full_name': 'Student One',
          'student_id': 'AIM001', 'role': 'student', 'is_verified': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
        'isAdmin': false,
      },
      {
        'name': 'admin user',
        'json': {
          'id': 'uuid-2', 'email': 'admin@aim.edu', 'full_name': 'Admin User',
          'student_id': 'AIM000', 'role': 'admin', 'is_verified': true,
          'created_at': '2025-06-15T12:00:00Z',
        },
        'isAdmin': true,
      },
      {
        'name': 'builder user',
        'json': {
          'id': 'uuid-3', 'email': 'builder@aim.edu', 'full_name': 'Builder Bob',
          'student_id': 'AIM002', 'role': 'builder', 'is_verified': true,
          'created_at': '2026-02-01T08:30:00Z',
        },
        'isAdmin': true,
      },
      {
        'name': 'unverified user',
        'json': {
          'id': 'uuid-4', 'email': 'new@gmail.com', 'full_name': 'New User',
          'student_id': '', 'role': 'student', 'is_verified': false,
          'created_at': '2026-02-19T00:00:00Z',
        },
        'isAdmin': false,
      },
      {
        'name': 'missing fields — defaults',
        'json': <String, dynamic>{},
        'isAdmin': false,
      },
    ];

    for (final tc in testCases) {
      test('parses ${tc['name']}', () {
        final user = UserModel.fromJson(tc['json'] as Map<String, dynamic>);
        expect(user.isAdmin, tc['isAdmin']);
        expect(user.id, isNotNull);
        expect(user.email, isNotNull);
      });
    }

    test('toJson round-trip preserves data', () {
      final user = UserModel(
        id: 'test-id',
        email: 'test@aim.edu',
        fullName: 'Test User',
        studentId: 'AIM999',
        role: 'student',
        isVerified: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final json = user.toJson();
      expect(json['email'], 'test@aim.edu');
      expect(json['full_name'], 'Test User');
      expect(json['role'], 'student');
    });
  });

  group('AuthResponse', () {
    test('parses from JSON', () {
      final json = {
        'token': 'jwt-abc',
        'refresh_token': 'refresh-xyz',
        'user': {
          'id': 'u1', 'email': 'test@aim.edu', 'full_name': 'Test',
          'student_id': 'S1', 'role': 'student', 'is_verified': true,
          'created_at': '2026-01-01T00:00:00Z',
        },
      };
      final response = AuthResponse.fromJson(json);
      expect(response.token, 'jwt-abc');
      expect(response.refreshToken, 'refresh-xyz');
      expect(response.user.email, 'test@aim.edu');
    });

    test('handles missing fields gracefully', () {
      final response = AuthResponse.fromJson({});
      expect(response.token, isEmpty);
      expect(response.refreshToken, isEmpty);
      expect(response.user.email, isEmpty);
    });
  });

  group('Auth Events', () {
    test('AuthCheckStatus is an AuthEvent', () {
      expect(AuthCheckStatus(), isA<AuthEvent>());
    });

    test('AuthGoogleSignIn is an AuthEvent', () {
      expect(AuthGoogleSignIn(), isA<AuthEvent>());
    });

    test('AuthLogout is an AuthEvent', () {
      expect(AuthLogout(), isA<AuthEvent>());
    });
  });

  group('Auth States', () {
    test('AuthInitial is correct type', () {
      expect(AuthInitial(), isA<AuthState>());
    });

    test('AuthLoading is correct type', () {
      expect(AuthLoading(), isA<AuthState>());
    });

    test('AuthError contains message', () {
      final state = AuthError(message: 'test error');
      expect(state.message, 'test error');
    });

    test('AuthAuthenticated contains user', () {
      final user = UserModel(
        id: 'id', email: 'e@aim.edu', fullName: 'Test',
        studentId: 'S1', role: 'student', isVerified: true,
        createdAt: DateTime.now(),
      );
      final state = AuthAuthenticated(user: user);
      expect(state.user.email, 'e@aim.edu');
    });
  });
}
