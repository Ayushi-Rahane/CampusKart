import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<dynamic> _wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getWishlist();
      if (mounted) {
        setState(() {
          _wishlistItems = items;
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

  Future<void> _removeFromWishlist(String itemId, int index) async {
    try {
      await ApiService.removeFromWishlist(itemId);
      if (mounted) {
        setState(() {
          _wishlistItems.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from wishlist'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
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
                      const Expanded(
                        child: Text(
                          'My Wishlist',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_wishlistItems.length} item${_wishlistItems.length != 1 ? 's' : ''} saved',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Wishlist items
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _wishlistItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Your wishlist is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Text('Items you love will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchWishlist,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _wishlistItems.length,
                            itemBuilder: (context, index) {
                              final item = _wishlistItems[index];
                              return _buildWishlistCard(item, index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(dynamic item, int index) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(itemId: item['_id']),
          ),
        );
        _fetchWishlist(); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 90,
                height: 90,
                child: item['imageUrl'] != null
                    ? Image.network(item['imageUrl'], fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (item['category'] ?? 'Other').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${item['price'] ?? 0}',
                    style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ],
              ),
            ),
            // Remove button
            GestureDetector(
              onTap: () => _removeFromWishlist(item['_id'], index),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
