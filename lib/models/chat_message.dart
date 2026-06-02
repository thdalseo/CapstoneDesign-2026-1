import 'app_notification.dart';

class ChatMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final AppNotification? notification;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isMe,
    this.notification,
  });
}
