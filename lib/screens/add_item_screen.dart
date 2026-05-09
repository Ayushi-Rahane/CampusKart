import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this if needed for MimeType, but usually we can omit it if http handles it or we use mime package.
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme.dart';
import '../services/api_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  String _selectedCategory = 'Furniture';
  XFile? _imageFile;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _postAd() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add title, price, and an image')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Not authenticated. Please login again.');

      var request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/items'));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['title'] = _titleController.text;
      request.fields['description'] = _descController.text;
      request.fields['price'] = _priceController.text;
      request.fields['category'] = _selectedCategory == 'Others' 
          ? _otherCategoryController.text.isNotEmpty ? _otherCategoryController.text : 'Others'
          : _selectedCategory;

      if (kIsWeb) {
        // For web
        final bytes = await _imageFile!.readAsBytes();
        
        String ext = _imageFile!.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) ext = 'jpeg';
        
        request.files.add(http.MultipartFile.fromBytes(
          'image', 
          bytes, 
          filename: _imageFile!.name.isNotEmpty ? _imageFile!.name : 'upload.$ext',
          contentType: MediaType('image', ext),
        ));
      } else {
        // For mobile
        request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item posted successfully!'), backgroundColor: Colors.green));
          Navigator.pop(context); // Go back or reset
        }
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to post item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.headerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.headerTeal,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Post an Ad',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'What are you selling today?',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  
                  if (_imageFile != null) 
                    Stack(
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[200],
                          ),
                          child: kIsWeb 
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => setState(() => _imageFile = null),
                            ),
                          ),
                        )
                      ]
                    )
                  else
                    Row(
                      children: [
                        _buildPhotoBox(Icons.camera_alt_outlined, 'Take Photo', () => _pickImage(ImageSource.camera)),
                        const SizedBox(width: 15),
                        _buildPhotoBox(Icons.image_outlined, 'Gallery', () => _pickImage(ImageSource.gallery)),
                      ],
                    ),
                  const SizedBox(height: 25),
                  
                  const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'e.g. White Study Chair'),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(hintText: 'Enter amount'),
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 20),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildCatBtn('Furniture'),
                      _buildCatBtn('Electronics'),
                      _buildCatBtn('Books'),
                      _buildCatBtn('Others'),
                    ],
                  ),

                  if (_selectedCategory == 'Others') ...[
                    const SizedBox(height: 15),
                    TextField(
                      controller: _otherCategoryController,
                      decoration: const InputDecoration(hintText: 'Please specify category'),
                    ),
                  ],

                  const SizedBox(height: 25),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe what you are selling, its condition, etc...',
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _postAd,
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Post Ad Now'),
                          ],
                        ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoBox(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppTheme.headerTeal, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.headerTeal),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.headerTeal, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatBtn(String label) {
    bool active = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        width: 150, 
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentYellow : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey),
          ),
        ),
      ),
    );
  }
}
