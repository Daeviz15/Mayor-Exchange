import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/chat_message.dart';
import '../../admin/providers/admin_role_provider.dart';

/// Provider to fetch chat messages for a transaction (real-time stream)
final transactionChatProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, transactionId) {
  final client = ref.read(supabaseClientProvider);

  return client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('transaction_id', transactionId)
      .order('created_at', ascending: true)
      .map((rows) => rows.map((row) => ChatMessage.fromJson(row)).toList());
});

/// Provider to send a chat message
final sendMessageProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);

  return ({
    required String transactionId,
    required String message,
    required String senderType,
    List<String>? attachments,
  }) async {
    final userId = client.auth.currentUser!.id;

    await client.from('chat_messages').insert({
      'transaction_id': transactionId,
      'sender_id': userId,
      'sender_type': senderType,
      'message': message,
      'attachments': attachments ?? [],
    });
  };
});

/// Check if current user is admin (includes super_admin)
/// Alias for isAdminProvider from admin_role_provider for backward compatibility
/// NOTE: This now uses the real-time streaming version from admin_role_provider
final isCurrentUserAdminProvider = isAdminProvider;

// NOTE: isSuperAdminProvider is now defined in admin_role_provider.dart
// Import it from there: import '../../admin/providers/admin_role_provider.dart';

/// Centralized provider that tracks unread counts for ALL transactions
/// This replaces per-transaction streams to save network resources
final adminUnreadCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final client = ref.read(supabaseClientProvider);
  final isAdminAsync = ref.watch(isCurrentUserAdminProvider);

  // Use a controller to emit updates map
  final controller = StreamController<Map<String, int>>();
  final currentCounts = <String, int>{};

  // Helper to emit current state
  void emitCounts() {
    if (!controller.isClosed) {
      controller.add(Map.from(currentCounts));
    }
  }

  bool isDisposed = false;

  void setup() async {
    if (isDisposed || controller.isClosed) return;

    final isAdmin = isAdminAsync.when(
      data: (val) => val,
      loading: () => false,
      error: (_, __) => false,
    );
    final targetSenderType = isAdmin ? 'user' : 'admin';

    // 1. Initial Batch Fetch using RPC or Group By query
    try {
      // Note: Supabase JS/Flutter doesn't easily support "group by" in basic select yet without RPC
      // So we fetch id and transaction_id for unread messages and aggregate client-side
      // Ideally this should also be an RPC for massive scale, but this is already 100x better than N streams
      final result = await client
          .from('chat_messages')
          .select('transaction_id')
          .eq('is_read', false)
          .eq('sender_type', targetSenderType);

      currentCounts.clear();
      for (final row in result as List) {
        final txId = row['transaction_id'] as String;
        currentCounts[txId] = (currentCounts[txId] ?? 0) + 1;
      }

      emitCounts();
    } catch (e) {
      debugPrint('Error fetching unread counts: $e');
    }
  }

  setup();

  // 2. Single Global Subscription for updates
  final channel = client.channel('admin_unread_counts');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_messages',
        callback: (payload) {
          final isAdmin = isAdminAsync.asData?.value ?? false;
          final targetSenderType = isAdmin ? 'user' : 'admin';

          // Handle INSERT (New Message)
          if (payload.eventType == PostgresChangeEvent.insert) {
            final newMsg = payload.newRecord;
            if (newMsg['sender_type'] == targetSenderType &&
                newMsg['is_read'] == false) {
              final txId = newMsg['transaction_id'] as String;
              currentCounts[txId] = (currentCounts[txId] ?? 0) + 1;
              emitCounts();
            }
          }

          // Handle UPDATE (Mark Read)
          else if (payload.eventType == PostgresChangeEvent.update) {
            final oldMsg = payload.oldRecord;
            final newMsg = payload.newRecord;
            final txId = newMsg['transaction_id'] as String;

            // If message became read
            if (oldMsg['is_read'] == false && newMsg['is_read'] == true) {
              if (currentCounts.containsKey(txId)) {
                currentCounts[txId] = (currentCounts[txId]! - 1).clamp(0, 9999);
                if (currentCounts[txId] == 0) currentCounts.remove(txId);
                emitCounts();
              }
            }
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    isDisposed = true;
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Legacy provider alias that now selects from the efficient central provider
/// This keeps existing UI code working without changes
final unreadCountStreamProvider =
    StreamProvider.family<int, String>((ref, transactionId) {
  final countsAsync = ref.watch(adminUnreadCountsProvider);

  return countsAsync.when(
    data: (counts) => Stream.value(counts[transactionId] ?? 0),
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Mark messages as read
final markMessagesReadProvider = Provider((ref) {
  final client = ref.read(supabaseClientProvider);

  return (String transactionId, String readerType) async {
    // Mark messages from opposite party as read
    final targetType = readerType == 'admin' ? 'user' : 'admin';
    await client
        .from('chat_messages')
        .update({'is_read': true})
        .eq('transaction_id', transactionId)
        .eq('sender_type', targetType)
        .eq('is_read', false);
  };
});

/// Get transaction info for chat header (cached)
final chatTransactionInfoProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, transactionId) async {
  final client = ref.read(supabaseClientProvider);

  final result = await client
      .from('transactions')
      .select('id, type, status, details, created_at')
      .eq('id', transactionId)
      .maybeSingle();

  return result;
});

/// Global unread count across ALL transactions for the current user/admin
final globalUnreadCountProvider = StreamProvider<int>((ref) {
  final client = ref.read(supabaseClientProvider);
  final isAdminAsync = ref.watch(isCurrentUserAdminProvider);

  final controller = StreamController<int>();
  bool isDisposed = false;

  void updateCount() async {
    if (isDisposed || controller.isClosed) return;

    final isAdmin = isAdminAsync.when(
      data: (val) => val,
      loading: () => false,
      error: (_, __) => false,
    );
    final targetSenderType = isAdmin ? 'user' : 'admin';

    try {
      final result = await client
          .from('chat_messages')
          .select('id')
          .eq('is_read', false)
          .eq('sender_type', targetSenderType);

      if (!isDisposed && !controller.isClosed) {
        controller.add((result as List).length);
      }
    } catch (e) {
      if (!isDisposed && !controller.isClosed) {
        controller.add(0);
      }
    }
  }

  updateCount();

  // Listen to ALL chat changes
  final channel = client.channel('global_unread');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'chat_messages',
        callback: (_) => updateCount(),
      )
      .subscribe();

  ref.onDispose(() {
    isDisposed = true;
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Provider to listen for NEW chat messages to trigger in-app notifications
final chatNotificationProvider = StreamProvider<ChatMessage>((ref) {
  final client = ref.read(supabaseClientProvider);
  final isAdminAsync = ref.watch(isCurrentUserAdminProvider);

  final controller = StreamController<ChatMessage>();

  final channel = client.channel('chat_notifications');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        callback: (payload) {
          final isAdmin = isAdminAsync.asData?.value ?? false;
          final newMsg = ChatMessage.fromJson(payload.newRecord);

          // Only notify if message is from the other party
          if (isAdmin && newMsg.senderType == 'user') {
            controller.add(newMsg);
          } else if (!isAdmin && newMsg.senderType == 'admin') {
            controller.add(newMsg);
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Tracks the ID of the chat currently being viewed to suppress redundant notifications
final currentChatIdProvider = StateProvider<String?>((ref) => null);

/// Declarative provider to manage the "active" chat room state.
/// When a widget watches this, the currentChatId is set.
/// When the widget is disposed, the currentChatId is cleared automatically.
final activeChatRoomProvider =
    Provider.autoDispose.family<void, String>((ref, id) {
  // Capture the notifier BEFORE any async operations or dispose callbacks
  final notifier = ref.read(currentChatIdProvider.notifier);

  // Use a delayed update to avoid "setting state during build" errors
  Future.microtask(() {
    notifier.state = id;
  });

  ref.onDispose(() {
    // Use the captured notifier instead of calling ref.read inside onDispose
    notifier.state = null;
  });
});

/// Widget that listens for new chat messages and shows in-app notifications
class ChatNotificationListener extends ConsumerWidget {
  final Widget child;
  const ChatNotificationListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ChatMessage>>(chatNotificationProvider,
        (previous, next) {
      final newMsg = next.asData?.value;
      if (newMsg == null) return;

      // Only show notification if NOT currently in that specific chat
      final currentChatId = ref.read(currentChatIdProvider);
      if (currentChatId != newMsg.transactionId) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.chat_bubble,
                    color: Color(0xFFFF7043), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newMsg.senderType == 'admin'
                            ? 'Support'
                            : 'Message from User',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                      Text(
                        newMsg.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return child;
  }
}
