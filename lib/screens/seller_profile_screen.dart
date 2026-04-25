import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _sellerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSellerProfile(widget.sellerId);
      if (mounted) {
        setState(() {
          _sellerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showRateDialog() {
    double rating = 5.0;
    final feedbackCtrl = TextEditingController();

    // Just let them rate without specifying itemId for now, or use the first sold item they bought?
    // The API requires an itemId. We can either ask the user which item, or just use a generic ID/make it optional.
    // Let's check if the user has bought anything from this seller.
    String? purchasedItemId;
    final soldItems = _sellerData?['soldItems'] as List<dynamic>?;
    // We would need to know the current user ID to match buyerId. Let's do a simple workaround:
    // If there are sold items, just pick the first one for the demo, or modify the API.
    // Ideally we should select the item from a list of purchased items.
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Rate Seller'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?'),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.accentYellow,
                        size: 32,
                      ),
                      onPressed: () {
                        setStateSB(() => rating = index + 1.0);
                      },
                    );
                  }),
                ),
                TextField(
                  controller: feedbackCtrl,
                  decoration: const InputDecoration(labelText: 'Feedback (Optional)'),
                  maxLines: 2,
                ),
                if (soldItems != null && soldItems.isNotEmpty)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Which item?'),
                    items: soldItems.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['_id'],
                        child: Text(item['title'], overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => purchasedItemId = val,
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (purchasedItemId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an item you purchased')));
                    return;
                  }
                  
                  try {
                    await ApiService.rateSeller(widget.sellerId, purchasedItemId!, rating.toInt(), feedbackCtrl.text);
                    if (mounted) {
                      Navigator.pop(ctx); // close the rating box
                      
                      // Show success alert
                      showDialog(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text('Success')]),
                          content: const Text('Your rating has been submitted successfully!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(alertCtx), child: const Text('OK')),
                          ],
                        ),
                      );
                      
                      _loadProfile();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_sellerData == null) return const Scaffold(body: Center(child: Text('Failed to load profile')));

    final seller = _sellerData!['seller'];
    final available = _sellerData!['availableItems'] as List<dynamic>;
    final sold = _sellerData!['soldItems'] as List<dynamic>;
    final ratings = seller['ratings'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.headerTeal,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(seller['name'][0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(seller['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppTheme.accentYellow, size: 16),
                                const SizedBox(width: 4),
                                Text('${seller['averageRating']} (${ratings.length} reviews)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showRateDialog,
                    icon: const Icon(Icons.rate_review, color: AppTheme.primaryPink),
                    label: const Text('Rate Seller', style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryPink,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryPink,
              tabs: const [
                Tab(text: 'Items for Sale'),
                Tab(text: 'Reviews'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemList(available, emptyText: 'No items available'),
                  _buildReviews(ratings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<dynamic> items, {required String emptyText}) {
    if (items.isEmpty) return Center(child: Text(emptyText, style: const TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: item['imageUrl'] != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover))
              : const Icon(Icons.image, size: 50),
            title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₹${item['price']} • ${item['category']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => ItemDetailScreen(itemId: item['_id'])));
            },
          ),
        );
      },
    );
  }

  Widget _buildReviews(List<dynamic> ratings) {
    if (ratings.isEmpty) return const Center(child: Text('No reviews yet', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ratings.length,
      itemBuilder: (ctx, i) {
        final r = ratings[i];
        final buyerName = r['buyerId'] != null ? r['buyerId']['name'] : 'User';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                        color: AppTheme.accentYellow,
                        size: 16,
                      )),
                    ),
                  ],
                ),
                if (r['feedback'] != null && r['feedback'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(r['feedback'], style: const TextStyle(color: Colors.black87)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
