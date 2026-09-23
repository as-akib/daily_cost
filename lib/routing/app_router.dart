import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../data/repositories/providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_wizard_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/summary/spending_summary_screen.dart';
import '../features/can_i_afford/can_i_afford_screen.dart';
import '../features/savings_goal/savings_goal_screen.dart';
import '../features/settings/settings_screen.dart';

final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    final sbUser = Supabase.instance.client.auth.currentUser;
    final currentUid = user?.uid ?? sbUser?.id;

    // 1. Shuru-te jodi auth check na hoye thake
    if (authState.isLoading && currentUid == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2. Kono user login kora na thakle direct AuthScreen
    if (user == null && sbUser == null) {
      return const AuthScreen();
    }

    // 3. User login thakle Profile Check
    final profileAsync = ref.watch(currentProfileProvider);

    // Jodi profile peye jay ebong onboarding completed hoy -> Main App
    if (profileAsync.hasValue) {
      final profile = profileAsync.value;
      if (profile != null && profile.isOnboardingCompleted) {
        return const MainNavigationShell();
      }
      return const OnboardingWizardScreen();
    }

    // Error ashle ba notun account hole direct Onboarding
    if (profileAsync.hasError) {
      return const OnboardingWizardScreen();
    }

    // 4. Fallback: Jodi stream shurute late kore, default Onboarding
    return const OnboardingWizardScreen();
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SpendingSummaryScreen(),
    CanIAffordScreen(),
    SavingsGoalScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor:
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.primaryContainer,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon:
            Icon(Icons.pie_chart_rounded, color: AppColors.primary),
            label: 'Breakdown',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon:
            Icon(Icons.help_rounded, color: AppColors.primary),
            label: 'Afford?',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon:
            Icon(Icons.savings_rounded, color: AppColors.primary),
            label: 'Savings',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
            Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}