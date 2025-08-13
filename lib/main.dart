import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'core/router.dart';
import 'core/ui_helpers.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_data_provider.dart';
import 'models/quiz_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for consistent appearance
  UIHelpers.setSystemUIOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surfaceCharcoal,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters for quiz history
  Hive.registerAdapter(QuizHistoryEntryAdapter());

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const CyberQuizApp());
}

class CyberQuizApp extends StatelessWidget {
  const CyberQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use SupabaseAuthService for real authentication
        Provider<AuthService>(
          create: (_) => SupabaseAuthService(),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? AuthProvider(authService),
        ),
        // Quiz data provider for local-first data management
        ChangeNotifierProvider<QuizDataProvider>(
          create: (_) => QuizDataProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.createRouter(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
