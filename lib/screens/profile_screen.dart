import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'item_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<dynamic> _purchases = [];
  List<dynamic> _sales = [];
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
      final data = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          _profile = data['profile'];
          _profile!['averageRating'] = data['averageRating'];
          _purchases = data['purchases'];
          _sales = data['sales'];
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

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile?['name']);
    final phoneCtrl = TextEditingController(text: _profile?['phone']);
    final addressCtrl = TextEditingController(text: _profile?['address']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.updateProfile(nameCtrl.text, phoneCtrl.text, addressCtrl.text);
                _loadProfile();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            const SizedBox(height: 10),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.changePassword(currentCtrl.text, newCtrl.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profile == null) {
      return const Scaffold(body: Center(child: Text('Failed to load profile')));
    }

    final name = _profile!['name'] ?? 'User';

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
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(_profile!['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppTheme.accentYellow, size: 16),
                                const SizedBox(width: 4),
                                Text('${_profile!['averageRating']} Rating', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _showEditProfileDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text('Password', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white, 
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Logout', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white, 
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Details
            if (_profile!['phone'] != null && _profile!['phone'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [const Icon(Icons.phone, color: Colors.grey, size: 20), const SizedBox(width: 10), Text(_profile!['phone'])]),
              ),
            if (_profile!['address'] != null && _profile!['address'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [const Icon(Icons.location_on, color: Colors.grey, size: 20), const SizedBox(width: 10), Expanded(child: Text(_profile!['address']))]),
              ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryPink,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryPink,
              tabs: const [
                Tab(text: 'Purchases'),
                Tab(text: 'My Sales'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemList(_purchases, emptyText: 'No purchases yet', isPurchase: true),
                  _buildItemList(_sales, emptyText: 'No items sold yet', isSale: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(List<dynamic> items, {required String emptyText, bool isSale = false, bool isPurchase = false}) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: Colors.grey)));
    }
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
            trailing: isSale
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(item['_id']),
                  )
                : (isPurchase
                    ? IconButton(
                        icon: const Icon(Icons.rate_review, color: Colors.green),
                        onPressed: () => _showRateDialog(item['sellerId'], item['_id']),
                      )
                    : const Icon(Icons.chevron_right)),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (ctx) => ItemDetailScreen(itemId: item['_id'])));
              _loadProfile();
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(String itemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deleteItem(itemId);
                _loadProfile();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(String sellerId, String itemId) {
    double rating = 5.0;
    final feedbackCtrl = TextEditingController();
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Rate Purchase'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setStateSB(() => pickedImage = img);
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: Text(pickedImage == null ? 'Attach Picture' : 'Picture Selected'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    List<int>? bytes;
                    String? filename;
                    if (pickedImage != null) {
                      bytes = await pickedImage!.readAsBytes();
                      filename = pickedImage!.name;
                    }
                    
                    await ApiService.rateSeller(
                      sellerId, 
                      itemId, 
                      rating.toInt(), 
                      feedbackCtrl.text, 
                      imageBytes: bytes, 
                      imageFileName: filename,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted successfully!')));
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
}
