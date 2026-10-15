import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiPlanes {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>?> obtenerPlanNegocio(int idNegocio) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/planes/negocio/$idNegocio'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      print('Error obtener plan del negocio: $e');
      return null;
    }
  }
}
