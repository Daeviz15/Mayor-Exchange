import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../../core/services/notification_service.dart';

// State model for a notification
class AdminNotification {
  final String title;
  final String message;
  final TransactionType? type;

  AdminNotification({
    required this.title,
    required this.message,
    this.type,
  });
}

final adminNotificationProvider =
    NotifierProvider<AdminNotificationNotifier, AdminNotification?>(
        AdminNotificationNotifier.new);

class AdminNotificationNotifier extends Notifier<AdminNotification?> {
  RealtimeChannel? _subscription;

  @override
  AdminNotification? build() {
    // Initialize subscription on build
    _initSubscription();
    // Clean up on dispose
    ref.onDispose(() {
      _subscription?.unsubscribe();
    });
    return null; // Initial state
  }

  void _initSubscription() {
    final client = ref.read(supabaseClientProvider);

    // Listen for INSERT (New Orders)
    _subscription = client
        .channel('public:transactions')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'transactions',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final typeStr = newRecord['type'] as String;
              final type = TransactionType.fromString(typeStr);

              state = AdminNotification(
                title: 'New Order Received',
                message:
                    'A new ${type.name.toUpperCase()} request has been submitted.',
                type: type,
              );
            })
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'transactions',
            callback: (payload) {
              final newRecord = payload.newRecord;
              final oldRecord = payload.oldRecord;

              final statusNew = newRecord['status'];
              final statusOld = oldRecord['status'];

              if (statusNew == 'verification_pending' &&
                  statusOld != 'verification_pending') {
                state = AdminNotification(
                  title: 'Proof Uploaded',
                  message: 'A user has uploaded payment proof. Please verify.',
                );
              }
            })
        .subscribe();
  }
}
