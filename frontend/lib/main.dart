import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'core/utils/google_signin_button.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/request_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerGoogleSignInButton();
  
  print('🚀 [App] Starting Make It Exist app...');
  print('🔐 [App] Google Sign-In initialization complete');
  
  // Initialize API client
  final apiClient = ApiClient();
  
  // Initialize repositories
  final authRepo = AuthRepository(apiClient: apiClient);
  final requestRepo = RequestRepository(apiClient: apiClient);
  final adminRepo = AdminRepository(apiClient: apiClient);
  
  print('📦 [App] Repositories initialized');
  
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepo),
        RepositoryProvider<RequestRepository>(create: (_) => requestRepo),
        RepositoryProvider<AdminRepository>(create: (_) => adminRepo),
      ],
      child: const MakeItExistApp(),
    ),
  );
}
