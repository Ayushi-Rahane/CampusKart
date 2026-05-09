import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _savedItems = [];
  List<dynamic> _requestedItems = [];
  bool _isLoadingSaved = true;
  bool _isLoadingRequested = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSavedWishlist();
    _fetchRequestWishlist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedWishlist() async {
    setState(() => _isLoadingSaved = true);
    try {
      final items = await ApiService.getWishlist();
      if (mounted) setState(() { _savedItems = items; _isLoadingSaved = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
      }
    }
  }

  Future<void> _fetchRequestWishlist() async {
    setState(() => _isLoadingRequested = true);
    try {
      final items = await ApiService.getRequestWishlist();
      if (mounted) setState(() { _requestedItems = items; _isLoadingRequested = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRequested = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
      }
    }
  }

  Future<void> _removeFromSaved(String itemId, int index) async {
    try {
      await ApiService.removeFromWishlist(itemId);
      if (mounted) {
        setState(() => _savedItems.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from saved'), duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    }
  }

  Future<void> _removeRequest(String id, int index) async {
    try {
      await ApiService.removeRequestWishlist(id);
      if (mounted) {
        setState(() => _requestedItems.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request removed'), duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    }
  }

  void _showAddRequestDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCat = 'Electronics';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Request an Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                const SizedBox(height: 6),
                Text("Can't find what you need? We'll notify you when it's listed!", style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Item name (e.g. PC Mouse, Textbook)', prefixIcon: Icon(Icons.search))),
                const SizedBox(height: 14),
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['Electronics', 'Furniture', 'Books', 'Others'].map((c) {
                    bool active = selectedCat == c;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedCat = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.primaryPink : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: active ? Colors.white : Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Description (optional)', prefixIcon: Icon(Icons.description_outlined))),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an item name')));
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final result = await ApiService.addRequestWishlist(nameCtrl.text.trim(), selectedCat, descCtrl.text.trim());
                      if (result['matched'] == true) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.celebration, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Great news! A matching item is already available!')),
                                ],
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request added! We\'ll notify you when it\'s available.'), backgroundColor: Colors.green));
                      }
                      _fetchRequestWishlist();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                    }
                  },
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_active, size: 18), SizedBox(width: 8), Text('Request & Notify Me')]),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.headerTeal, Color(0xFF90D5D5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Text('My Wishlist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle), child: const Icon(Icons.favorite, color: Colors.white, size: 20)),
                  ]),
                  const SizedBox(height: 16),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      labelColor: AppTheme.headerTeal,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bookmark, size: 16), const SizedBox(width: 6), Text('Saved (${_savedItems.length})')])),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.notifications_active, size: 16), const SizedBox(width: 6), Text('Requested (${_requestedItems.length})')])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildSavedTab(), _buildRequestedTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SAVED PRODUCTS TAB ====================
  Widget _buildSavedTab() {
    if (_isLoadingSaved) return const Center(child: CircularProgressIndicator());
    if (_savedItems.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bookmark_border, size: 70, color: Colors.grey[300]),
        const SizedBox(height: 14),
        Text('No saved products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Text('Bookmark items you want to buy later', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _fetchSavedWishlist,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _savedItems.length,
        itemBuilder: (context, index) => _buildSavedCard(_savedItems[index], index),
      ),
    );
  }

  Widget _buildSavedCard(dynamic item, int index) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: item['_id'])));
        _fetchSavedWishlist();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 90, height: 90, child: item['imageUrl'] != null
              ? Image.network(item['imageUrl'], fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFFF0F0F0), child: const Icon(Icons.broken_image, color: Colors.grey)))
              : Container(color: const Color(0xFFF0F0F0), child: const Icon(Icons.image, color: Colors.grey))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.accentYellow.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
              child: Text((item['category'] ?? 'Other').toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87)),
            ),
            const SizedBox(height: 6),
            Text('₹${item['price'] ?? 0}', style: const TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.w900, fontSize: 17)),
          ])),
          GestureDetector(
            onTap: () => _removeFromSaved(item['_id'], index),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.favorite, color: Colors.red, size: 22)),
          ),
        ]),
      ),
    );
  }

  // ==================== REQUESTED ITEMS TAB ====================
  Widget _buildRequestedTab() {
    if (_isLoadingRequested) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      // Add Request Button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GestureDetector(
          onTap: _showAddRequestDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primaryPink.withOpacity(0.1), AppTheme.primaryPink.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryPink.withOpacity(0.3), style: BorderStyle.solid),
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryPink.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add_alert, color: AppTheme.primaryPink, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Request an Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142))),
                const SizedBox(height: 2),
                Text("Can't find it? Get notified when it's listed", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryPink),
            ]),
          ),
        ),
      ),
      // Requested items list
      Expanded(
        child: _requestedItems.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none, size: 70, color: Colors.grey[300]),
              const SizedBox(height: 14),
              Text('No requests yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[500])),
              const SizedBox(height: 6),
              Text('Request items you want and get notified', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ]))
          : RefreshIndicator(
              onRefresh: _fetchRequestWishlist,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _requestedItems.length,
                itemBuilder: (context, index) => _buildRequestCard(_requestedItems[index], index),
              ),
            ),
      ),
    ]);
  }

  Widget _buildRequestCard(dynamic request, int index) {
    final bool matched = request['matched'] == true;
    final matchedItem = request['matchedItemId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: matched ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: matched ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(matched ? Icons.check_circle : Icons.schedule, color: matched ? Colors.green : Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(request['itemName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142))),
            const SizedBox(height: 3),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.accentYellow.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                child: Text((request['category'] ?? '').toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: matched ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(matched ? Icons.check_circle : Icons.hourglass_empty, size: 10, color: matched ? Colors.green[700] : Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(matched ? 'Available' : 'Waiting', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: matched ? Colors.green[700] : Colors.orange[700])),
                  ],
                ),
              ),
            ]),
          ])),
          GestureDetector(
            onTap: () => _removeRequest(request['_id'], index),
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.red, size: 18)),
          ),
        ]),
        if (request['description'] != null && request['description'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(request['description'], style: TextStyle(fontSize: 12, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (matched && matchedItem != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final itemId = matchedItem is Map ? matchedItem['_id'] : matchedItem.toString();
              await Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(itemId: itemId)));
              _fetchRequestWishlist();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.2))),
              child: Row(children: [
                if (matchedItem is Map && matchedItem['imageUrl'] != null)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 44, child: Image.network(matchedItem['imageUrl'], fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 18))))),
                if (matchedItem is Map && matchedItem['imageUrl'] != null) const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(matchedItem is Map ? (matchedItem['title'] ?? 'View Item') : 'View Matched Item', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.green)),
                  if (matchedItem is Map && matchedItem['price'] != null)
                    Text('₹${matchedItem['price']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.green[700])),
                ])),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.green[400]),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
