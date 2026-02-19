import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:make_it_exist/app.dart';
import 'package:make_it_exist/core/network/api_client.dart';
import 'package:make_it_exist/data/repositories/auth_repository.dart';
import 'package:make_it_exist/data/repositories/request_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;
  late AuthRepository authRepo;
  late RequestRepository requestRepo;

  setUp(() {
    apiClient = ApiClient();
    authRepo = AuthRepository(apiClient: apiClient);
    requestRepo = RequestRepository(apiClient: apiClient);
  });

  group('Login Screen UI Tests', () {
    testWidgets('Login screen renders correctly with Google Sign-In button',
        (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(create: (_) => authRepo),
            RepositoryProvider<RequestRepository>(create: (_) => requestRepo),
          ],
          child: const MakeItExistApp(),
        ),
      );

      // Wait for splash screen to transition
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should see the login screen
      expect(find.text('Make It Exist'), findsWidgets);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // Info boxes should be visible
      expect(find.textContaining('AIM'), findsWidgets);
      expect(find.textContaining('automatically'), findsOneWidget);
    });

    testWidgets('Login screen shows rocket emoji', (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(create: (_) => authRepo),
            RepositoryProvider<RequestRepository>(create: (_) => requestRepo),
          ],
          child: const MakeItExistApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('Google Sign-In button is tappable', (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(create: (_) => authRepo),
            RepositoryProvider<RequestRepository>(create: (_) => requestRepo),
          ],
          child: const MakeItExistApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      final button = find.widgetWithText(ElevatedButton, 'Sign in with Google');
      expect(button, findsOneWidget);

      // Verify button exists and can be found
      final ElevatedButton buttonWidget = tester.widget(button);
      expect(buttonWidget.onPressed, isNotNull);
    });
  });

  group('Navigation UI Tests', () {
    testWidgets('Unauthenticated user cannot access /home', (tester) async {
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(create: (_) => authRepo),
            RepositoryProvider<RequestRepository>(create: (_) => requestRepo),
          ],
          child: const MakeItExistApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be redirected to login, not home
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}
