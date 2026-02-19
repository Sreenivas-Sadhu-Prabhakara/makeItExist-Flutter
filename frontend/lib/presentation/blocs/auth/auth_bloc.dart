import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exceptions.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthGoogleSignIn>(_onGoogleSignIn);
    on<AuthEmailSignIn>(_onEmailSignIn);
    on<AuthLogout>(_onLogout);

    if (kIsWeb) {
      // Listen for Google user changes on web
      authRepository.googleUserChanges.listen((account) async {
        if (account != null) {
          // User signed in via button, complete backend login
          add(AuthGoogleSignIn());
        }
      });
    }
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    final isLoggedIn = await authRepository.isLoggedIn();
    if (isLoggedIn) {
      try {
        final user = await authRepository.getProfile();
        emit(AuthAuthenticated(user: user));
      } catch (_) {
        await authRepository.logout();
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(AuthGoogleSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user: response.user));
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Sign-in failed. Please try again.'));
    }
  }

  Future<void> _onEmailSignIn(AuthEmailSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.signInWithEmail(event.email, event.password);
      emit(AuthAuthenticated(user: response.user));
    } on ApiException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'Sign-in failed. Please try again.'));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
