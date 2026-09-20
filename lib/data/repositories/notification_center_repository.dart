import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification_item.dart';

final notificationCenterRepositoryProvider = Provider<NotificationCenterRepository>((ref) {
  return NotificationCenterRepository();
});

final notificationListProvider = StateNotifierProvider<NotificationListNotifier, List<AppNotificationItem>>((ref) {
  final repo = ref.watch(notificationCenterRepositoryProvider);
  return NotificationListNotifier(repo);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider);
  return notifications.where((item) => !item.isRead).length;
});

class NotificationCenterRepository {
  static const String _storageKey = 'dailycost_inapp_notifications_v1';

  Future<List<AppNotificationItem>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      final defaultItems = _getDefaultSeedNotifications();
      await saveNotifications(defaultItems);
      return defaultItems;
    }
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => AppNotificationItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return _getDefaultSeedNotifications();
    }
  }

  Future<void> saveNotifications(List<AppNotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }

  List<AppNotificationItem> _getDefaultSeedNotifications() {
    final now = DateTime.now();
    return [
      AppNotificationItem(
        id: 'update-v1-2',
        title: '🚀 DailyCost Update v1.2 Released',
        message: 'Welcome to DailyCost! Enjoy lightning-fast Supabase sync, fresh #00BBA7 emerald theme, 30 inspiring daily quotes, and real-time budget insights.',
        type: NotificationType.appUpdate,
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AppNotificationItem(
        id: 'dev-notice-sync',
        title: '📢 Developer Note: High Speed Local-First Sync',
        message: 'Your expenses and budget settings now update with sub-millisecond local speed and sync seamlessly to the cloud in the background. No loading lag!',
        type: NotificationType.developerNotice,
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      AppNotificationItem(
        id: 'weekly-insight-seed',
        title: '📊 Weekly Spending Insight',
        message: 'Keep an eye out every Sunday at 11:30 PM for a personalized breakdown of your highest spending category for the week!',
        type: NotificationType.weeklySummary,
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}

class NotificationListNotifier extends StateNotifier<List<AppNotificationItem>> {
  final NotificationCenterRepository _repo;

  NotificationListNotifier(this._repo) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.loadNotifications();
  }

  Future<void> addNotification(AppNotificationItem item) async {
    final updated = [item, ...state.where((n) => n.id != item.id)];
    state = updated;
    await _repo.saveNotifications(updated);
  }

  Future<void> markAsRead(String id) async {
    final updated = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    state = updated;
    await _repo.saveNotifications(updated);
  }

  Future<void> markAllAsRead() async {
    final updated = state.map((item) => item.copyWith(isRead: true)).toList();
    state = updated;
    await _repo.saveNotifications(updated);
  }

  Future<void> deleteNotification(String id) async {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    await _repo.saveNotifications(updated);
  }
}
