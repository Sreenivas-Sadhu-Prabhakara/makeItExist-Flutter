import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_bloc.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_event.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_state.dart';
import 'package:make_it_exist/data/repositories/auth_repository.dart';
import 'package:make_it_exist/data/models/user_model.dart';
import 'package:make_it_exist/core/network/api_exceptions.dart';

// ── Mocks ────────────────────────────────────────────────────────────
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  // ── Test Data ────────────────────────────────────────────────────────
  final testUser = UserModel(
    id: 'test-uuid-1234',
    email: 'student@aim.edu',
    fullName: 'Test Student',
    studentId: 'AIM2024001',
    role: 'student',
    isVerified: true,
    createdAt: DateTime(2026, 1, 1),
  );

  final testAuthResponse = AuthResponse(
    token: 'jwt-token-abc',
    refreshToken: 'refresh-token-xyz',
    user: testUser,
  );

  group('AuthBloc', () {
    // ── AuthCheckStatus ────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when user is already logged in',
      setUp: () {
        when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockAuthRepo.getProfile()).thenAnswer((_) async => testUser);
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.user.email, 'email', 'student@aim.edu'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when no saved token',
      setUp: () {
        when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => false);
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when token is invalid (profile fails)',
      setUp: () {
        when(() => mockAuthRepo.isLoggedIn()).thenAnswer((_) async => true);
        when(() => mockAuthRepo.getProfile()).thenThrow(Exception('401'));
        when(() => mockAuthRepo.logout()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [isA<AuthUnauthenticated>()],
    );

    // ── AuthGoogleSignIn ───────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful Google sign-in',
      setUp: () {
        when(() => mockAuthRepo.signInWithGoogle())
            .thenAnswer((_) async => testAuthResponse);
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthGoogleSignIn()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>()
            .having((s) => s.user.email, 'email', 'student@aim.edu'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when Google sign-in is cancelled',
      setUp: () {
        when(() => mockAuthRepo.signInWithGoogle()).thenThrow(
          ApiException(message: 'Google sign-in was cancelled'),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthGoogleSignIn()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Google sign-in was cancelled'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on unexpected Google sign-in failure',
      setUp: () {
        when(() => mockAuthRepo.signInWithGoogle())
            .thenThrow(Exception('network error'));
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthGoogleSignIn()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Sign-in failed. Please try again.'),
      ],
    );

    // ── Data-driven: Multiple error scenarios ──────────────────────────

    final errorScenarios = <Map<String, dynamic>>[
      {
        'name': 'domain not allowed error',
        'exception': ApiException(message: 'email domain not allowed'),
        'expectedMessage': 'email domain not allowed',
      },
      {
        'name': 'token verification failed',
        'exception': ApiException(message: 'invalid Google token'),
        'expectedMessage': 'invalid Google token',
      },
      {
        'name': 'server error',
        'exception': ApiException(message: 'Internal server error', statusCode: 500),
        'expectedMessage': 'Internal server error',
      },
    ];

    for (final scenario in errorScenarios) {
      blocTest<AuthBloc, AuthState>(
        'emits error for scenario: ${scenario['name']}',
        setUp: () {
          when(() => mockAuthRepo.signInWithGoogle())
              .thenThrow(scenario['exception'] as ApiException);
        },
        build: () => AuthBloc(authRepository: mockAuthRepo),
        act: (bloc) => bloc.add(AuthGoogleSignIn()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            scenario['expectedMessage'] as String,
          ),
        ],
      );
    }

    // ── AuthLogout ─────────────────────────────────────────────────────

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on logout',
      setUp: () {
        when(() => mockAuthRepo.logout()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(AuthLogout()),
      expect: () => [isA<AuthUnauthenticated>()],
    );
  });
}
