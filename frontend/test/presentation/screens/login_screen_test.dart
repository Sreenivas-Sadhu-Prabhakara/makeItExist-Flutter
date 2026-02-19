import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_bloc.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_event.dart';
import 'package:make_it_exist/presentation/blocs/auth/auth_state.dart';
import 'package:make_it_exist/presentation/screens/auth/login_screen.dart';
import 'package:mocktail/mocktail.dart';

// ── Mock AuthBloc so we never need a real ApiClient or AuthRepository ──
class MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

// ── Mock HttpClient to return a transparent 1×1 PNG for Image.network ──
class _MockHttpClient extends Mock implements HttpClient {
  @override
  bool autoUncompress = true;
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

/// A transparent 1×1 PNG so Image.network has something to decode.
final _kTransparentPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG signature
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1×1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, // RGBA
  0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41, 0x54, // IDAT
  0x78, 0x9c, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xe5, 0x27, 0xde,
  0xfc,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, // IEND
  0xae, 0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = _MockHttpClient();
    final request = _MockHttpClientRequest();
    final response = _MockHttpClientResponse();
    final headers = _MockHttpHeaders();

    // Wire up mock chain: client → request → response
    when(() => client.getUrl(any())).thenAnswer((_) async => request);
    when(() => request.headers).thenReturn(headers);
    when(() => request.close()).thenAnswer((_) async => response);
    when(() => response.compressionState)
        .thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(() => response.contentLength).thenReturn(_kTransparentPng.length);
    when(() => response.statusCode).thenReturn(HttpStatus.ok);
    when(() => response.listen(any(),
            onDone: any(named: 'onDone'),
            onError: any(named: 'onError'),
            cancelOnError: any(named: 'cancelOnError')))
        .thenAnswer((inv) {
      final onData =
          inv.positionalArguments[0] as void Function(List<int>);
      final onDone = inv.namedArguments[#onDone] as void Function()?;
      onData(_kTransparentPng);
      onDone?.call();
      return const Stream<List<int>>.empty().listen((_) {});
    });

    return client;
  }
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    // Default: bloc starts in AuthInitial
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders app title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Make It Exist'), findsOneWidget);
    });

    testWidgets('renders tagline', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(
        find.text("If it can be imagined, we'll Make It Exist."),
        findsOneWidget,
      );
    });

    testWidgets('renders Google Sign-In button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders rocket emoji', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('renders info box with AIM reference', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.textContaining('AIM'), findsWidgets);
    });

    testWidgets('renders info box about auto-creation', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.textContaining('automatically'), findsOneWidget);
    });

    testWidgets('renders lock emoji for security info', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('🔒'), findsOneWidget);
    });

    testWidgets('renders graduation cap emoji', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('🎓'), findsOneWidget);
    });
  });

  group('LoginScreen — Data-Driven State Tests', () {
    // Data-driven: test different auth states affect the UI
    final stateTestCases = <Map<String, dynamic>>[
      {
        'name': 'initial state shows Sign in button',
        'state': AuthInitial(),
        'expectButton': 'Sign in with Google',
        'expectSpinner': false,
      },
      {
        'name': 'loading state shows spinner',
        'state': AuthLoading(),
        'expectButton': 'Signing in...',
        'expectSpinner': true,
      },
    ];

    for (final tc in stateTestCases) {
      testWidgets(tc['name'] as String, (tester) async {
        final state = tc['state'] as AuthState;
        when(() => mockAuthBloc.state).thenReturn(state);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        // Check expected button text
        expect(find.text(tc['expectButton'] as String), findsOneWidget);

        // Check spinner presence
        if (tc['expectSpinner'] as bool) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else {
          expect(find.byType(CircularProgressIndicator), findsNothing);
        }
      });
    }
  });
}
