import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/app_notification_item.dart';
import '../../data/repositories/notification_center_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(notificationListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationListProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Mark all as read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _buildNotificationCard(context, ref, item, isDark);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up! Push notifications, weekly insights, and system announcements will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotificationItem item,
    bool isDark,
  ) {
    final typeConfig = _getTypeConfig(item.type);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.overBudget,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) {
        ref.read(notificationListProvider.notifier).deleteNotification(item.id);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (!item.isRead) {
            ref.read(notificationListProvider.notifier).markAsRead(item.id);
          }
          _showDetailDialog(context, item, isDark);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: !item.isRead
                ? (isDark
                    ? const Color(0xFF042F2E).withAlpha(180)
                    : const Color(0xFFE6FFFA))
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: !item.isRead
                  ? AppColors.primary.withAlpha(isDark ? 160 : 120)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: !item.isRead ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: !item.isRead
                    ? AppColors.primary.withAlpha(isDark ? 35 : 20)
                    : Colors.black.withAlpha(isDark ? 15 : 4),
                blurRadius: !item.isRead ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeConfig.color.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(typeConfig.icon, color: typeConfig.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Title & Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: !item.isRead ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeConfig.color.withAlpha(isDark ? 30 : 18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeConfig.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: typeConfig.color,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(item.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, AppNotificationItem item, bool isDark) {
    final typeConfig = _getTypeConfig(item.type);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeConfig.color.withAlpha(isDark ? 40 : 25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(typeConfig.icon, color: typeConfig.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeConfig.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: typeConfig.color,
                          ),
                        ),
                        Text(
                          _formatTimestamp(item.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeConfig _getTypeConfig(NotificationType type) {
    switch (type) {
      case NotificationType.weeklySummary:
        return _TypeConfig(
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF00BBA7),
          label: 'Weekly Insight',
        );
      case NotificationType.overspendAlert:
        return _TypeConfig(
          icon: Icons.warning_amber_rounded,
          color: AppColors.overBudget,
          label: 'Budget Alert',
        );
      case NotificationType.nightlyReview:
        return _TypeConfig(
          icon: Icons.nightlight_round,
          color: const Color(0xFF8B5CF6),
          label: 'Nightly Review',
        );
      case NotificationType.monthEndSummary:
        return _TypeConfig(
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFF59E0B),
          label: 'Savings Goal',
        );
      case NotificationType.developerNotice:
        return _TypeConfig(
          icon: Icons.campaign_rounded,
          color: const Color(0xFF3B82F6),
          label: 'Announcement',
        );
      case NotificationType.appUpdate:
        return _TypeConfig(
          icon: Icons.system_update_rounded,
          color: const Color(0xFF10B981),
          label: 'App Update',
        );
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM, yyyy').format(date);
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _TypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
