import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const goldAccent = Color(0xFFFFD700);
    const goldSecondary = Color(0xFFDAA520);
    const goldDark = Color(0xFFB8860B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [goldAccent, goldSecondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: goldAccent.withAlpha(100),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFF1E1700), size: 16),
                SizedBox(width: 4),
                Text(
                  'VIP MEMBER PASS',
                  style: TextStyle(
                    color: Color(0xFF1E1700),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background atmospheric golden glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldAccent.withAlpha(isDark ? 55 : 35),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldSecondary.withAlpha(isDark ? 50 : 25),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // VIP Golden Crown Emblem
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF1A6), goldAccent, goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldAccent.withAlpha(140),
                          blurRadius: 32,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF1E1700),
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand Title
                  Text(
                    'DailyCost VIP Member',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? goldAccent : goldDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elevate your wealth management with institutional-grade VIP financial tools & AI intelligence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // COMING SOON Luxury Golden Glass Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark ? const Color(0xFF1E1708) : Colors.white,
                      border: Border.all(
                        color: goldAccent.withAlpha(150),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldAccent.withAlpha(isDark ? 40 : 25),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: goldAccent.withAlpha(35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: goldAccent.withAlpha(100),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, size: 16, color: goldDark),
                              SizedBox(width: 6),
                              Text(
                                'EXCLUSIVE VIP PRIVILEGES',
                                style: TextStyle(
                                  color: goldDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'VIP Access Coming Soon…',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isDark ? goldAccent : goldDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We are crafting an ultra-luxurious experience. Early VIP supporters will receive exclusive discounted lifetime pricing.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Section Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'UPCOMING VIP MEMBER PRIVILEGES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isDark ? goldAccent : goldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Feature Cards
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.psychology_rounded,
                    iconColor: goldAccent,
                    title: 'Smart AI Spending Predictor',
                    subtitle: 'Real-time forecast for month-end savings based on current burn rate and habits.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.cloud_sync_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Multi-Device Instant Cloud Sync',
                    subtitle: 'Synchronize your budget across all your phones, tablets, and web dashboards seamlessly.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.picture_as_pdf_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Export PDF & Excel Tax Reports',
                    subtitle: 'Generate beautifully designed, auditor-ready monthly and annual expense statements.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.all_inclusive_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Unlimited Custom VIP Envelopes & Goals',
                    subtitle: 'Create separate envelopes for vacations, investments, family funds, and projects.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    icon: Icons.palette_rounded,
                    iconColor: goldAccent,
                    title: 'Exclusive Golden & Obsidian Themes',
                    subtitle: 'Unlock custom luxury app icon designs, neon cards, and VIP personalized home layouts.',
                  ),

                  const SizedBox(height: 28),

                  // Bottom Notify Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A2000), Color(0xFF1E1700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: goldAccent.withAlpha(120),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldAccent.withAlpha(60),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: goldAccent.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: goldAccent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VIP Priority Notification',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'You will receive an in-app priority invitation on VIP launch.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [goldAccent, goldSecondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'VIP Active',
                            style: TextStyle(
                              color: Color(0xFF1E1700),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E170A) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3D3012) : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
