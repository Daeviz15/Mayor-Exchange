import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transaction_service.dart';

/// Transaction Chat Screen with Pinned Header
/// Allows user/admin to communicate about a specific transaction
class TransactionChatScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final String transactionTitle;
  final Map<String, dynamic>? transactionDetails;

  const TransactionChatScreen({
    super.key,
    required this.transactionId,
    this.transactionTitle = 'Transaction Chat',
    this.transactionDetails,
  });

  @override
  ConsumerState<TransactionChatScreen> createState() =>
      _TransactionChatScreenState();
}

class _TransactionChatScreenState extends ConsumerState<TransactionChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAndMarkRead();
  }

  void _checkAdminAndMarkRead() async {
    // Get admin status from the real-time StreamProvider
    // Use asData?.value pattern for Riverpod 3 compatibility
    final isAdmin = ref.read(isCurrentUserAdminProvider).asData?.value ?? false;

    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });

    final readerType = _isAdmin ? 'admin' : 'user';
    await ref.read(markMessagesReadProvider)(widget.transactionId, readerType);

    // Invalidate the unread count provider to force a refresh
    ref.invalidate(unreadCountStreamProvider(widget.transactionId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(sendMessageProvider)(
        transactionId: widget.transactionId,
        message: message,
        senderType: _isAdmin ? 'admin' : 'user',
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _copyTransactionId() {
    Clipboard.setData(ClipboardData(text: widget.transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction ID copied!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Declarative tracking of the active chat room.
    // This automatically sets/clears currentChatIdProvider in providers.
    ref.watch(activeChatRoomProvider(widget.transactionId));

    final chatAsync = ref.watch(transactionChatProvider(widget.transactionId));
    // Use singleTransactionProvider for real-time status updates
    final txAsync = ref.watch(singleTransactionProvider(widget.transactionId));
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          widget.transactionTitle,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Pinned Transaction Info Header
          _buildPinnedHeader(txAsync),

          // Messages List
          Expanded(
            child: chatAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Start the conversation!',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                      ],
                    ),
                  );
                }

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, currentUserId);
                  },
                );
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPinnedHeader(AsyncValue<TransactionModel?> txAsync) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: txAsync.when(
        loading: () => const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const SizedBox.shrink(),
        data: (tx) {
          if (tx == null) return const SizedBox.shrink();

          final details = tx.details;
          final type = tx.type.name;
          final status = tx.status.name;
          final cardName = details['card_name'] as String? ??
              details['crypto_symbol'] as String? ??
              '';
          final amount = details['card_value_usd'] ??
              details['amount_usd'] ??
              details['amount'] ??
              '';

          return Row(
            children: [
              // Transaction Type Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getStatusColor(status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatType(type),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (cardName.isNotEmpty) ...[
                          const Text(' • ',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Flexible(
                            child: Text(
                              cardName,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Transaction ID (tappable to copy)
                        GestureDetector(
                          onTap: _copyTransactionId,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ID: ${widget.transactionId.substring(0, 8)}...',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.copy,
                                  size: 12, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                        if (amount.toString().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            '\$$amount',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: AppColors.primaryOrange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, String? currentUserId) {
    // SenderType-based alignment: If I'm admin and message is from admin, it's mine.
    // If I'm user and message is from user, it's mine.
    final isMe = (_isAdmin && message.senderType == 'admin') ||
        (!_isAdmin && message.senderType == 'user');
    final isSystem = message.isSystemMessage;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryOrange : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            if (isMe)
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender label for received messages
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.senderType == 'admin' ? 'Support' : 'Customer',
                  style: TextStyle(
                    color: message.senderType == 'admin'
                        ? const Color(0xFFFF8A65)
                        : const Color(0xFF81C784),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFFE5E5EA),
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color:
                        isMe ? Colors.white.withOpacity(0.7) : Colors.white24,
                    fontSize: 9,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  String _formatType(String type) {
    switch (type) {
      case 'sellGiftCard':
        return 'Sell Gift Card';
      case 'buyGiftCard':
        return 'Buy Gift Card';
      case 'sellCrypto':
        return 'Sell Crypto';
      case 'buyCrypto':
        return 'Buy Crypto';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sellGiftCard':
      case 'buyGiftCard':
        return Icons.card_giftcard;
      case 'sellCrypto':
      case 'buyCrypto':
        return Icons.currency_bitcoin;
      default:
        return Icons.receipt;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}
