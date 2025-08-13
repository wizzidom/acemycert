import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_data_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuizData();
    });
  }

  Future<void> _initializeQuizData() async {
    final authProvider = context.read<AuthProvider>();
    final quizDataProvider = context.read<QuizDataProvider>();
    
    if (authProvider.user != null && !quizDataProvider.isInitialized) {
      await quizDataProvider.initialize(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    int selectedIndex = 0;
    if (currentLocation.startsWith('/dashboard')) {
      selectedIndex = 0;
    } else if (currentLocation.startsWith('/history')) {
      selectedIndex = 1;
    } else if (currentLocation.startsWith('/profile')) {
      selectedIndex = 2;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCharcoal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: selectedIndex == 0,
                onTap: () => context.go('/dashboard'),
              ),
              _buildNavItem(
                context,
                icon: MdiIcons.history,
                label: 'History',
                isSelected: selectedIndex == 1,
                onTap: () => context.go('/history'),
              ),
              _buildNavItem(
                context,
                icon: MdiIcons.account,
                label: 'Profile',
                isSelected: selectedIndex == 2,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentGreen.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.accentGreen 
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? AppTheme.accentGreen 
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected 
                    ? FontWeight.w600 
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}