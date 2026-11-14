import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fertiflow/services/app_state.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static IconData _mapIcon(String? iconStr) {
    switch (iconStr) {
      case 'bug_report':
        return Icons.bug_report_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'grass':
        return Icons.grass_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final notifications = AppState.instance.notifications;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.cardColor,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  AppState.instance.markAllNotificationsRead();
                },
                child: Text(
                  'Tandai Dibaca',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: theme.dividerColor.withValues(alpha: 0.5), height: 1.0),
            ),
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final String id = notif['id'] ?? '';
                    final String title = notif['title'] ?? '';
                    final bool isRead = notif['isRead'] ?? false;
                    final String body = notif['body'] ?? '';
                    final String time = notif['time'] ?? '';

                    final String iconStr = notif['icon'] ?? '';
                    final int colorValue = notif['color'] ?? 0xFF9E9E9E;
                    final Color accentColor = Color(colorValue);
                    final IconData icon = _mapIcon(iconStr);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(id),
                        direction: DismissDirection.startToEnd,
                        onDismissed: (_) {
                          AppState.instance.markNotificationRead(id);
                        },
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (!isRead) {
                              AppState.instance.markNotificationRead(id);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? theme.cardColor
                                  : (isDark
                                      ? accentColor.withValues(alpha: 0.08)
                                      : accentColor.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead
                                    ? theme.dividerColor.withValues(alpha: 0.5)
                                    : accentColor.withValues(alpha: 0.25),
                                width: isRead ? 1.0 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Circle
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? theme.dividerColor.withValues(alpha: 0.3)
                                        : accentColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: isRead
                                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                        : accentColor,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title and Subtitle Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            time,
                                            style: GoogleFonts.shareTechMono(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        body,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Unread Status Dot Indicator
                                if (!isRead) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
