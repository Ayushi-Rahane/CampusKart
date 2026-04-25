import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';
import 'seller_profile_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Map<String, dynamic>? _item;
  bool _isLoading = true;
  bool _isWishlisted = false;
  bool _wishlistLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    _currentUserId = await ApiService.getSavedUserId();
    try {
      final item = await ApiService.getItemDetail(widget.itemId);
      final wishlisted = await ApiService.checkWishlist(widget.itemId);
      if (mounted) {
        setState(() {
          _item = item;
          _isWishlisted = wishlisted;
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

  Future<void> _toggleWishlist() async {
    if (_wishlistLoading) return;
    setState(() => _wishlistLoading = true);
    try {
      if (_isWishlisted) {
        await ApiService.removeFromWishlist(widget.itemId);
      } else {
        await ApiService.addToWishlist(widget.itemId);
      }
      if (mounted) {
        setState(() {
          _isWishlisted = !_isWishlisted;
          _wishlistLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isWishlisted ? 'Added to wishlist ❤️' : 'Removed from wishlist'),
            backgroundColor: _isWishlisted ? Colors.green : Colors.grey[700],
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _wishlistLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  void _contactSeller() async {
    if (_item == null) return;
    final seller = _item!['seller'];
    final sellerId = _item!['sellerId'];
    final itemId = _item!['_id'];

    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller info not available')),
      );
      return;
    }

    try {
      final conversationId = await ApiService.startConversation(sellerId, itemId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserName: seller?['name'] ?? 'Seller',
              itemTitle: _item!['title'],
              itemImageUrl: _item!['imageUrl'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Item not found')),
      );
    }

    final item = _item!;
    final seller = item['seller'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section with overlay buttons
                  Stack(
                    children: [
                      // Item Image
                      Container(
                        height: 380,
                        width: double.infinity,
                        color: const Color(0xFFF5F5F5),
                        child: item['imageUrl'] != null
                            ? Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (ctx, err, stack) =>
                                    const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                              )
                            : const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                      ),

                      // Top bar: Back, Share, Wishlist
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircleButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.pop(context, _isWishlisted),
                            ),
                            Row(
                              children: [
                                _buildCircleButton(icon: Icons.share_outlined, onTap: () {}),
                                const SizedBox(width: 10),
                                _buildCircleButton(
                                  icon: _isWishlisted ? Icons.favorite : Icons.favorite_border,
                                  iconColor: _isWishlisted ? Colors.red : Colors.black87,
                                  onTap: _toggleWishlist,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Category badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            (item['category'] ?? 'OTHER').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Content Section
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    transform: Matrix4.translationValues(0, -20, 0),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'] ?? '',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${item['price'] ?? 0}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primaryPink),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Location and time
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              item['location'] ?? 'Campus',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 16),
                            Text('•', style: TextStyle(color: Colors.grey[400])),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(item['createdAt']),
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                        const SizedBox(height: 10),
                        Text(
                          item['description'] ?? 'No description provided.',
                          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
                        ),

                        const SizedBox(height: 28),

                        // Seller Card
                        if (seller != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => SellerProfileScreen(sellerId: item['sellerId'])),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.12)),
                              ),
                              child: Row(
                                children: [
                                  // Seller avatar
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.headerTeal.withOpacity(0.5),
                                    child: Text(
                                      (seller['name'] ?? 'S')[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2D3142)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          seller['name'] ?? 'Seller',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Tap to view profile & ratings',
                                          style: TextStyle(fontSize: 12, color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.headerTeal.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chevron_right, color: AppTheme.headerTeal, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          if (item['status'] == 'sold')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey[200],
              child: SafeArea(top: false, child: const Center(child: Text('This item has been sold', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)))),
            )
          else if (_currentUserId != null && item['sellerId'] != _currentUserId)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _contactSeller,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryPink,
                          side: const BorderSide(color: AppTheme.primaryPink, width: 2),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await ApiService.buyItem(widget.itemId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item purchased successfully!')));
                              _loadItem(); // Reload to show sold status
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Buy Now', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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

  Widget _buildCircleButton({required IconData icon, VoidCallback? onTap, Color iconColor = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}
