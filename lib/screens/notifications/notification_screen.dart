import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  /// 채팅 알림 탭 시 호출 — room_id 전달
  final Future<void> Function(int roomId)? onChatRoomTap;

  const NotificationScreen({super.key, this.onChatRoomTap});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.load();
  }

  IconData _iconFor(String type) {
    return switch (type) {
      AppNotificationType.chat => Icons.chat_bubble_outline_rounded,
      AppNotificationType.match => Icons.people_outline_rounded,
      AppNotificationType.help => Icons.handshake_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _colorFor(String type) {
    return switch (type) {
      AppNotificationType.chat => AppTheme.primary,
      AppNotificationType.match => AppTheme.mint,
      AppNotificationType.help => AppTheme.coral,
      _ => AppTheme.textSecondary,
    };
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'notifications.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'notifications.minutes_ago'.tr(
        namedArgs: {'count': '${diff.inMinutes}'},
      );
    }
    if (diff.inHours < 24) {
      return 'notifications.hours_ago'.tr(
        namedArgs: {'count': '${diff.inHours}'},
      );
    }
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F0FE),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'notifications.empty_title'.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'notifications.empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    final color = _colorFor(notification.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
              await _service.markAsRead(notification.id);
              if (notification.type == AppNotificationType.chat &&
                  notification.sourceType == 'chat_room' &&
                  notification.sourceId != null) {
                final roomId = int.tryParse(notification.sourceId!);
                if (roomId != null && widget.onChatRoomTap != null) {
                  if (context.mounted) Navigator.pop(context);
                  await widget.onChatRoomTap!(roomId);
                }
              }
            },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: notification.isRead
                    ? AppTheme.border
                    : color.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(notification.type),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Text(
          'notifications.title'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          ValueListenableBuilder<List<AppNotification>>(
            valueListenable: _service.notifications,
            builder: (_, notifications, __) {
              final unread = notifications.where(
                (notification) => !notification.isRead,
              );
              if (unread.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _service.markAllAsRead,
                child: Text(
                  'notifications.mark_all_read'.tr(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: _service.notifications,
        builder: (_, notifications, __) {
          if (notifications.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 18),
            itemCount: notifications.length,
            itemBuilder: (_, index) =>
                _buildNotificationTile(notifications[index]),
          );
        },
      ),
    );
  }
}
