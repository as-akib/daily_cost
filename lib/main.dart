import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Initialization
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  // Notification Service Initialization
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(
    const ProviderScope(
      child: DailyCostApp(),
    ),
  );
}

class DailyCostApp extends ConsumerWidget {
  const DailyCostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppRouter(),
    );
  }
}