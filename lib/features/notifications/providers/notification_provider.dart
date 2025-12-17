import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../auth/providers/auth_providers.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'] ?? 'info',
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}

final notificationsProvider =
    NotifierProvider<UnreadNotificationNotifier, List<NotificationModel>>(
        UnreadNotificationNotifier.new);

// Provides the count of unread notifications
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  // Sort by date inside provider query usually, but simple filter here
  return notifications.where((n) => !n.isRead).length;
});

class UnreadNotificationNotifier extends Notifier<List<NotificationModel>> {
  RealtimeChannel? _subscription;

  @override
  List<NotificationModel> build() {
    final user = ref.watch(authControllerProvider).asData?.value;

    // Cancel previous subscription if any
    _subscription?.unsubscribe();

    if (user != null) {
      // Fire and forget fetch
      _fetchInitialNotifications(user.id);
      _subscribeToRealtime(user.id);
    }

    ref.onDispose(() {
      _subscription?.unsubscribe();
    });

    return [];
  }

  Future<void> _fetchInitialNotifications(String userId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final response = await client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final List<NotificationModel> notifications =
          (response as List).map((e) => NotificationModel.fromJson(e)).toList();

      state = notifications;
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  void _subscribeToRealtime(String userId) {
    final client = ref.read(supabaseClientProvider);

    // We subscribe to all INSERT events on the notifications table.
    // Since RLS is enabled and configured to only allow users to SELECT their own rows,
    // Supabase Realtime will automatically only send events for rows where user_id matches the current user.
    // Removing the explicit filter avoids potential type mismatch issues (UUID vs String).
    _subscription = client
        .channel('user_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            try {
              final newNotification =
                  NotificationModel.fromJson(payload.newRecord);
              state = [newNotification, ...state];
            } catch (e) {
              print('Error parsing notification payload: $e');
            }
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      // Optimistic update
      state = state.map((n) {
        if (n.id == notificationId) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            relatedId: n.relatedId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      await client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user == null) return;

      // Optimistic update
      state = state
          .map((n) => NotificationModel(
                id: n.id,
                userId: n.userId,
                title: n.title,
                message: n.message,
                type: n.type,
                relatedId: n.relatedId,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();

      final client = ref.read(supabaseClientProvider);
      await client
          .from('notifications')
          .update({'is_read': true}).eq('user_id', user.id);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).asData?.value;
    if (user != null) {
      await _fetchInitialNotifications(user.id);
    }
  }
}
