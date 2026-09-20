import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../data/repositories/providers.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_wizard_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/summary/spending_summary_screen.dart';
import '../features/can_i_afford/can_i_afford_screen.dart';
import '../features/savings_goal/savings_goal_screen.dart';
import '../features/settings/settings_screen.dart';

// Supabase Auth Changes ট্র্যাক করার জন্য লাইভ স্ট্রিম প্রোভাইডার
final supabaseAuthStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ১. সুপাবেজের লাইভ অথেনটিকেশন স্ট্রিম ওয়াচ করা
    final authStateAsync = ref.watch(supabaseAuthStateProvider);

    return authStateAsync.when(
      loading: () => const _SplashScreen(),
      error: (err, stack) => const AuthScreen(),
      data: (authState) {
        final session = authState.session ?? Supabase.instance.client.auth.currentSession;

        // ইউজার লগইন না থাকলে সরাসরি AuthScreen
        if (session == null) {
          return const AuthScreen();
        }

        // ২. সেশন পাওয়া গেলে প্রোফাইল স্টেট চেক
        final profileAsync = ref.watch(currentProfileProvider);

        return profileAsync.when(
          loading: () => const _SplashScreen(),
          error: (err, stack) {
            debugPrint('Profile fetch error: $err');
            // প্রফাইল লোডে সমস্যা হলেও প্রথমবার অনবোর্ডিং-এ পাঠিয়ে দেবে
            return const OnboardingWizardScreen();
          },
          data: (profile) {
            if (profile == null || !profile.isOnboardingCompleted) {
              return const OnboardingWizardScreen();
            }
            return const MainNavigationShell();
          },
        );
      },
    );
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                    const Color(0xFF0B0F19),
                    const Color(0xFF1E1B4B),
                    const Color(0xFF0F172A),
                  ]
                      : [
                    const Color(0xFFEEF2FF),
                    const Color(0xFFF3E8FF),
                    const Color(0xFFE0F2FE),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradient,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.appTagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}