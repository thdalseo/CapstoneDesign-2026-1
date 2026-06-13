import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../models/app_notification.dart';
import 'user_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _storageKey = 'app_notifications';
  static const _onceKey = 'app_notification_once_keys';
  static const _maxStored = 80;

  final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier<List<AppNotification>>([]);

  bool _loaded = false;
  bool _syncing = false;

  int get unreadCount =>
      notifications.value.where((notification) => !notification.isRead).length;

  Future<void> load({bool syncFromServer = true}) async {
    if (!_loaded) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          notifications.value = list
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList();
        } catch (_) {
          notifications.value = [];
        }
      }
      _loaded = true;
    }

    if (syncFromServer) {
      await refreshFromServer();
    }
  }

  Future<void> refreshFromServer() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final user = await UserService.loadUser(syncFromServer: false);
      final userId = user?.id ?? '';
      if (userId.isEmpty) return;

      final res = await ApiClient.get(
        '/api/notifications',
        params: {'user_id': userId},
      );
      final serverItems = (res['notifications'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();

      notifications.value = _merge(serverItems, notifications.value);
      await _save();
    } catch (_) {
      // 서버 미실행/오프라인이면 로컬 알림만 유지
    } finally {
      _syncing = false;
    }
  }

  Future<void> upsert(AppNotification notification) async {
    await load(syncFromServer: false);
    notifications.value = _merge([notification], notifications.value);
    await _save();
  }

  Future<void> add({
    required String type,
    required String title,
    required String body,
    String? sourceType,
    String? sourceId,
    bool syncToServer = false,
  }) async {
    await load(syncFromServer: false);

    if (syncToServer) {
      final serverNotification = await _createOnServer(
        type: type,
        title: title,
        body: body,
        sourceType: sourceType,
        sourceId: sourceId,
      );
      if (serverNotification != null) {
        await upsert(serverNotification);
        return;
      }
    }

    final now = DateTime.now();
    final notification = AppNotification(
      id: '${now.microsecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      sourceType: sourceType,
      sourceId: sourceId,
      createdAt: now,
      isRead: false,
    );

    notifications.value = [
      notification,
      ...notifications.value,
    ].take(_maxStored).toList();
    await _save();
  }

  Future<void> addOncePerDay({
    required String key,
    required String type,
    required String title,
    required String body,
  }) async {
    await load(syncFromServer: false);

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final uniqueKey = '$key:$today';
    final seen = prefs.getStringList(_onceKey) ?? [];
    if (seen.contains(uniqueKey)) return;

    await add(type: type, title: title, body: body);
    await prefs.setStringList(
      _onceKey,
      [uniqueKey, ...seen].take(_maxStored).toList(),
    );
  }

  Future<void> markAsRead(String id) async {
    await load(syncFromServer: false);
    AppNotification? target;
    for (final notification in notifications.value) {
      if (notification.id == id) {
        target = notification;
        break;
      }
    }

    notifications.value = notifications.value
        .map(
          (notification) => notification.id == id
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();
    await _save();

    final serverId = target?.serverId;
    if (serverId == null) return;
    try {
      final userId = await _currentUserId();
      if (userId.isEmpty) return;
      await ApiClient.patch('/api/notifications/$serverId/read', {
        'user_id': int.tryParse(userId) ?? 0,
      });
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    await load(syncFromServer: false);
    notifications.value = notifications.value
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    await _save();

    try {
      final userId = await _currentUserId();
      if (userId.isEmpty) return;
      await ApiClient.patch('/api/notifications/read-all', {
        'user_id': int.tryParse(userId) ?? 0,
      });
    } catch (_) {}
  }

  Future<void> clearAll() async {
    await load(syncFromServer: false);
    notifications.value = [];
    await _save();

    try {
      final userId = await _currentUserId();
      if (userId.isEmpty) return;
      await ApiClient.delete('/api/notifications', {
        'user_id': int.tryParse(userId) ?? 0,
      });
    } catch (_) {}
  }

  Future<AppNotification?> _createOnServer({
    required String type,
    required String title,
    required String body,
    String? sourceType,
    String? sourceId,
  }) async {
    try {
      final userId = await _currentUserId();
      if (userId.isEmpty) return null;
      final res = await ApiClient.post('/api/notifications', {
        'user_id': int.tryParse(userId) ?? 0,
        'type': type,
        'title': title,
        'body': body,
        if (sourceType != null) 'source_type': sourceType,
        if (sourceId != null) 'source_id': sourceId,
      });
      final raw = res['notification'] as Map<String, dynamic>?;
      return raw == null ? null : AppNotification.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<String> _currentUserId() async {
    final user = await UserService.loadUser(syncFromServer: false);
    return user?.id ?? '';
  }

  List<AppNotification> _merge(
    List<AppNotification> incoming,
    List<AppNotification> existing,
  ) {
    final byKey = <String, AppNotification>{};
    for (final item in [...existing, ...incoming]) {
      byKey[_keyFor(item)] = item;
    }
    final merged = byKey.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged.take(_maxStored).toList();
  }

  String _keyFor(AppNotification notification) {
    final serverId = notification.serverId;
    if (serverId != null) return 'server:$serverId';
    return 'local:${notification.id}';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(notifications.value.map((item) => item.toJson()).toList()),
    );
  }
}
