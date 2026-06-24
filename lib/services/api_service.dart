import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://dummyjson.com';

  Future<List<Map<String, dynamic>>> fetchProducts({int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products?limit=$limit'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['products']);
    }
    throw ApiException(
      'Error al obtener productos: ${response.statusCode}',
    );
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/categories'),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw ApiException(
      'Error al obtener categorías: ${response.statusCode}',
    );
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
