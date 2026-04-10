import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:noor/config.dart';
import 'package:noor/services/auth_service.dart';

class DataService {
  final _authService = AuthService();

  Future<List<Map<String, dynamic>>> getFeaturedProperties() async {
    try {
      final response = await http.get(Uri.parse('${AuraConfig.baseUrl}/properties/featured'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching properties: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserPortfolio() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${AuraConfig.baseUrl}/user/portfolio'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print("Error fetching portfolio: $e");
      return {};
    }
  }
}
