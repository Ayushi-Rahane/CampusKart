import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5001/api'; // Use 10.0.2.2 for Android emulator if needed, but for web localhost is fine

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userToken', token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  static Future<List<dynamic>> getItems() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/items?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      String errMsg = 'Failed to load items';
      try {
        errMsg = jsonDecode(response.body)['message'] ?? errMsg;
      } catch (_) {}
      throw Exception(errMsg);
    }
  }

  static Future<Map<String, dynamic>> getItemDetail(String itemId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/items/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load item');
    }
  }

  static Future<void> addToWishlist(String itemId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/wishlist/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to add to wishlist');
    }
  }

  static Future<void> removeFromWishlist(String itemId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/wishlist/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to remove from wishlist');
    }
  }

  static Future<List<dynamic>> getWishlist() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/wishlist'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load wishlist');
    }
  }

  static Future<bool> checkWishlist(String itemId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/wishlist/check/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isWishlisted'] ?? false;
    }
    return false;
  }

  // ---- Chat APIs ----

  static Future<String> startConversation(String sellerId, String itemId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/chat/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sellerId': sellerId, 'itemId': itemId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['conversationId'];
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to start conversation');
    }
  }

  static Future<List<dynamic>> getConversations() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/chat/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load conversations');
    }
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/chat/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load messages');
    }
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/chat/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send message');
    }
  }

  static Future<Map<String, dynamic>> getConversationInfo(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/chat/$conversationId/info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load conversation info');
    }
  }

  // Helper to get the current user's ID from the saved token (JWT decode)
  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;
    try {
      // Decode JWT payload (base64)
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      // Add padding if needed
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);
      return map['id'];
    } catch (_) {
      return null;
    }
  }

  // Save user info on login/register
  static Future<void> saveUserInfo(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    if (userData['user'] != null) {
      await prefs.setString('userId', userData['user']['id'] ?? '');
      await prefs.setString('userName', userData['user']['name'] ?? '');
      await prefs.setString('userEmail', userData['user']['email'] ?? '');
    }
  }

  static Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}

