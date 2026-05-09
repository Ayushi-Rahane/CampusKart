import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';
import 'wishlist_screen.dart';
import 'conversations_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest';
  int _unreadCount = 0;
  int _notifCount = -1;
  Timer? _pollingTimer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchUnreadCount();
    _fetchNotifCount();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchUnreadCount();
      _fetchNotifCount();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await ApiService.getUnreadTotal();
      if (mounted && count != _unreadCount) {
        if (count > _unreadCount && _unreadCount > 0) {
          // New message arrived!
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.mark_chat_unread, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('You have a new message!')),
                ],
              ),
              backgroundColor: AppTheme.headerTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConversationsScreen()),
                  );
                },
              ),
            ),
          );
        }
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  Future<void> _fetchNotifCount() async {
    try {
      final count = await ApiService.getNotificationUnreadCount();
      if (mounted && count != _notifCount) {
        if (count > _notifCount && _notifCount > 0) {
          // New notification!
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('An item you requested is now available!')),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => setState(() => _selectedIndex = 4), // 4 is Notifications tab
              ),
            ),
          );
        }
        setState(() => _notifCount = count);
      }
    } catch (_) {}
  }

  Future<void> _fetchItems() async {
    try {
      final items = await ApiService.getItems();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errorMsg = e.toString();
        if (errorMsg.contains('Not authorized') || errorMsg.contains('Not authenticated')) {
           ApiService.logout();
           Navigator.pushReplacementNamed(context, '/login');
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired. Please log in again.')));
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading items: $errorMsg')));
        }
      }
    }
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListTile(
                    title: const Text('Newest First'),
                    trailing: _sortBy == 'Newest' ? const Icon(Icons.check, color: AppTheme.primaryPink) : null,
                    onTap: () {
                      setState(() => _sortBy = 'Newest');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Price: Low to High'),
                    trailing: _sortBy == 'Price: Low to High' ? const Icon(Icons.check, color: AppTheme.primaryPink) : null,
                    onTap: () {
                      setState(() => _sortBy = 'Price: Low to High');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Price: High to Low'),
                    trailing: _sortBy == 'Price: High to Low' ? const Icon(Icons.check, color: AppTheme.primaryPink) : null,
                    onTap: () {
                      setState(() => _sortBy = 'Price: High to Low');
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildHomeBody() {
    var filteredItems = _selectedCategory == 'All' 
        ? List.from(_items)
        : _selectedCategory == 'Others'
            ? _items.where((item) {
                final cat = item['category'] ?? '';
                return cat != 'Furniture' && cat != 'Electronics' && cat != 'Books';
              }).toList()
            : _items.where((item) => item['category'] == _selectedCategory).toList();

    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_sortBy == 'Price: Low to High') {
      filteredItems.sort((a, b) => (a['price'] as num? ?? 0).compareTo(b['price'] as num? ?? 0));
    } else if (_sortBy == 'Price: High to Low') {
      filteredItems.sort((a, b) => (b['price'] as num? ?? 0).compareTo(a['price'] as num? ?? 0));
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Colored Header
            Container(
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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppTheme.accentYellow),
                            const SizedBox(width: 4),
                            const Flexible(
                              child: Text(
                                'Cummins College Campus', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white.withOpacity(0.8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedIndex = 4); // Go to Notifications tab
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                        if (_unreadCount > 0 || _notifCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar pulled up to overlap header
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search items...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showSortFilter,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.headerTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: Color(0xFF2D3142)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 5),

            // Categories
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildCatChip('All'),
                  _buildCatChip('Furniture'),
                  _buildCatChip('Electronics'),
                  _buildCatChip('Books'),
                  _buildCatChip('Others'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15),

            // Item Grid
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                  ? const Center(child: Text('No items found', style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailScreen(itemId: filteredItems[index]['_id']),
                              ),
                            );
                            _fetchItems(); // Refresh on return
                          },
                          child: _buildItemCard(filteredItems[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _selectedIndex == 1 ? 0 : _selectedIndex,
        children: [
          _buildHomeBody(),
          const SizedBox(), // Index 1 is Add Item (pushed)
          const WishlistScreen(),
          const ConversationsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex == 1 ? 0 : _selectedIndex, // keep highlight on previous tab if 1 is tapped
        selectedItemColor: AppTheme.primaryPink,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.pushNamed(context, '/add-item');
            _fetchItems(); // Refresh items when coming back
          } else {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 0) _fetchItems();
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Sell'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (_unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.primaryPink, shape: BoxShape.circle),
                      child: Text(_unreadCount > 9 ? '9+' : _unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (_notifCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: Text(_notifCount > 9 ? '9+' : _notifCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label) {
    bool active = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryPink : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primaryPink : Colors.grey.withOpacity(0.2)),
          boxShadow: active ? [
            BoxShadow(
              color: AppTheme.primaryPink.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: active ? Colors.white : Colors.grey[700]
          )
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  margin: const EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: item['imageUrl'] != null
                        ? Image.network(item['imageUrl'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : const Center(child: Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Text((item['category'] ?? 'OTHER').toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2D3142)), maxLines: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${item['price'] ?? 0}', style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.w900, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.headerTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.favorite_border, size: 14, color: AppTheme.headerTeal),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Expanded(child: Text(item['location'] ?? 'Campus', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600), maxLines: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
