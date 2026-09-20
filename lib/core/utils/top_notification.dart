import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum TopNotificationType { success, error, info, warning }

/// Utility to show smooth, elegant top notification banners
class TopNotification {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext? context, {
    required String message,
    String? title,
    TopNotificationType type = TopNotificationType.success,
    Duration duration = const Duration(milliseconds: 3200),
    VoidCallback? onUndo,
    OverlayState? overlayState,
  }) {
    // Dismiss any existing notification
    _currentEntry?.remove();
    _currentEntry = null;

    final targetOverlay = overlayState ??
        (context != null
            ? (Overlay.maybeOf(context, rootOverlay: true) ??
                Overlay.maybeOf(context))
            : null);
    if (targetOverlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onUndo: onUndo,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    targetOverlay.insert(entry);
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String? title;
  final String message;
  final TopNotificationType type;
  final Duration duration;
  final VoidCallback? onUndo;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    this.title,
    required this.message,
    required this.type,
    required this.duration,
    this.onUndo,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case TopNotificationType.success:
        return const Color(0xFF10B981); // Emerald Green
      case TopNotificationType.error:
        return const Color(0xFFEF4444); // Crimson Red
      case TopNotificationType.warning:
        return const Color(0xFFF59E0B); // Amber
      case TopNotificationType.info:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case TopNotificationType.success:
        return Icons.check_circle_rounded;
      case TopNotificationType.error:
        return Icons.error_rounded;
      case TopNotificationType.warning:
        return Icons.warning_amber_rounded;
      case TopNotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor().withAlpha(90),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onUndo != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          _dismiss();
                          widget.onUndo!();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withAlpha(40),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'UNDO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
