import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/certification/certification_detail_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/quiz_results_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/history/quiz_history_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../models/quiz.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        
        // Handle splash screen
        if (state.matchedLocation == '/splash') {
          return null; // Allow splash screen
        }
        
        // Redirect to login if not authenticated
        if (!isAuthenticated && 
            !state.matchedLocation.startsWith('/auth')) {
          return '/auth/login';
        }
        
        // Redirect to dashboard if authenticated and on auth screens
        if (isAuthenticated && 
            state.matchedLocation.startsWith('/auth')) {
          return '/dashboard';
        }
        
        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        
        // Authentication Routes
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        
        // Main App Shell with Bottom Navigation
        ShellRoute(
          builder: (context, state, child) {
            return MainNavigationScreen(child: child);
          },
          routes: [
            // Dashboard
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            
            // Quiz History
            GoRoute(
              path: '/history',
              builder: (context, state) => const QuizHistoryScreen(),
            ),
            
            // Profile
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        
        // Certification Detail
        GoRoute(
          path: '/certification/:id',
          builder: (context, state) {
            final certificationId = state.pathParameters['id']!;
            return CertificationDetailScreen(certificationId: certificationId);
          },
        ),
        
        // Quiz Screen
        GoRoute(
          path: '/quiz/:quizId',
          builder: (context, state) {
            final quizId = state.pathParameters['quizId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return QuizScreen(
              quizId: quizId,
              quiz: extra?['quiz'] as Quiz?,
            );
          },
        ),
        
        // Quiz Results
        GoRoute(
          path: '/quiz/:quizId/results',
          builder: (context, state) {
            final quizId = state.pathParameters['quizId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return QuizResultsScreen(
              quizId: quizId,
              quizResult: extra?['result'],
            );
          },
        ),
      ],
    );
  }
}