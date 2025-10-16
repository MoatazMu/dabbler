import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';


class PostsApiService {
  static const String _postsUrl = 'https://ekmhrxdwgegxkdkdukgq.supabase.co/rest/v1/posts';

  /// Private: builds headers for Supabase REST API calls
  Map<String, String> _buildHeaders() {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    final apiKey = Environment.supabaseAnonKey;
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  /// Public: fetch posts (headers are handled internally)
  Future<http.Response> fetchPosts() async {
    return await http.get(
      Uri.parse(_postsUrl),
      headers: _buildHeaders(),
    );
  }
}
