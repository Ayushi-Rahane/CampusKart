import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ApiService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.headerTeal, Color(0xFF90D5D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Messages',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_conversations.length} conversation${_conversations.length != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Conversations list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Text('Start chatting by contacting a seller!', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchConversations,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              return _buildConversationCard(_conversations[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(dynamic conv) {
    final otherUser = conv['otherUser'];
    final item = conv['item'];
    final name = otherUser?['name'] ?? 'User';
    final lastMsg = conv['lastMessage'] ?? '';
    final itemTitle = item?['title'] ?? '';
    final itemImage = item?['imageUrl'];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conv['_id'],
              otherUserName: name,
              itemTitle: itemTitle,
              itemImageUrl: itemImage,
            ),
          ),
        );
        _fetchConversations(); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.headerTeal.withOpacity(0.4),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D3142)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(conv['updatedAt']),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (itemTitle.isNotEmpty)
                    Text(
                      itemTitle,
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg.isNotEmpty ? lastMsg : 'No messages yet',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Item thumbnail
            if (itemImage != null)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    itemImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image, size: 20, color: Colors.grey),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
