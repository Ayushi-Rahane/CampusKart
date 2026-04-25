import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? itemTitle;
  final String? itemImageUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    this.itemTitle,
    this.itemImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await ApiService.getUserId();
    await _loadMessages();
    // Poll for new messages every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final messages = await ApiService.getMessages(widget.conversationId);
      if (mounted) {
        final hadMessages = _messages.length;
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        // Auto-scroll to bottom when new messages arrive
        if (messages.length > hadMessages) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ApiService.sendMessage(widget.conversationId, text);
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _messageController.text = text; // Restore text on failure
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    String time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0) {
      return time;
    } else if (diff.inDays == 1) {
      return 'Yesterday $time';
    } else {
      return '${date.day}/${date.month} $time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppTheme.headerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.itemTitle != null)
                    Text(
                      widget.itemTitle!,
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Item info banner
          if (widget.itemTitle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.headerTeal.withOpacity(0.15),
              child: Row(
                children: [
                  if (widget.itemImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.itemImageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 40, height: 40,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chatting about: ${widget.itemTitle}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No messages yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                            const SizedBox(height: 8),
                            Text('Say hi to start the conversation!', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['senderId'] == _currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.headerTeal.withOpacity(0.5),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryPink : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg['createdAt']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
