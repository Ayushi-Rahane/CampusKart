import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await ApiService.getNotifications();
      if (mounted) setState(() { _notifications = notifs; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      _fetchNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.headerTeal, Color(0xFF90D5D5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (_notifications.any((n) => n['read'] == false))
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none, size: 70, color: Colors.grey[300]),
                      const SizedBox(height: 14),
                      Text('No notifications yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final bool isRead = notif['read'] == true;
                          return GestureDetector(
                            onTap: () {
                              if (!isRead) _markAsRead(notif['_id']);
                              if (notif['itemId'] != null) {
                                final itemId = notif['itemId'] is Map ? notif['itemId']['_id'] : notif['itemId'];
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: itemId)));
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : AppTheme.primaryPink.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isRead ? Colors.transparent : AppTheme.primaryPink.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isRead ? Colors.grey[100] : AppTheme.primaryPink.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.inventory, color: isRead ? Colors.grey : AppTheme.primaryPink, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(notif['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isRead ? Colors.grey[800] : Colors.black))),
                                            Text(_timeAgo(notif['createdAt']), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(notif['message'] ?? '', style: TextStyle(fontSize: 13, color: isRead ? Colors.grey[600] : Colors.grey[800])),
                                      ],
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(margin: const EdgeInsets.only(left: 8, top: 4), width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryPink, shape: BoxShape.circle)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
