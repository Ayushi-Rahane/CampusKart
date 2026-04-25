import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';
import 'wishlist_screen.dart';
import 'conversations_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _fetchItems();
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

  @override
  Widget build(BuildContext context) {
    // Filter items based on category
    final filteredItems = _selectedCategory == 'All' 
        ? _items 
        : _selectedCategory == 'Others'
            ? _items.where((item) {
                final cat = item['category'] ?? '';
                return cat != 'Furniture' && cat != 'Electronics' && cat != 'Books';
              }).toList()
            : _items.where((item) => item['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white backgorund
      body: SafeArea(
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
                                'Block B, Campus', 
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
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
                      child: const Row(
                        children: [
                          SizedBox(width: 15),
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search items...', 
                              style: TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.headerTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Color(0xFF2D3142)),
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryPink,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.pushNamed(context, '/add-item');
            _fetchItems(); // Refresh items when coming back
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WishlistScreen()),
            );
            _fetchItems(); // Refresh on return
          } else if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConversationsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
