import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiNegocio {
  Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // CREAR NEGOCIO
  Future<bool> crearNegocio({
    required int idTipoNegocio,
    required int idPlan,
    required String nombre,
    String? descripcion,
    String? ubicacion,
    String? tarifa,
    double? latitud,
    double? longitud,
    String? telefono,
    String? sitioWeb,
    required List<Map<String, dynamic>> horarios,
  }) async {
    try {
      final token = await obtenerToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_tipo_negocio': idTipoNegocio,
          'id_plan': idPlan,
          'nombre': nombre,
          'descripcion': descripcion,
          'ubicacion': ubicacion,
          'tarifa': tarifa,
          'latitud': latitud,
          'longitud': longitud,
          'telefono': telefono,
          'sitio_web': sitioWeb,
          'horarios': horarios,
        }),
      );

      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // OBTENER TODOS LOS NEGOCIOS
  Future<List<dynamic>> obtenerTodos() async {
    try {
      final token = await obtenerToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // MIS NEGOCIOS
  Future<List<dynamic>> misNegocios() async {
    try {
      final token = await obtenerToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios/mis-negocios'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // OBTENER NEGOCIO POR ID
  Future<Map<String, dynamic>?> obtenerNegocio(int idNegocio) async {
    try {
      final token = await obtenerToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios/$idNegocio'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ACTUALIZAR NEGOCIO
  Future<bool> actualizarNegocio({
    required int idNegocio,
    required int idTipoNegocio,
    required String nombre,
    String? descripcion,
    String? ubicacion,
    String? tarifa,
    double? latitud,
    double? longitud,
    String? telefono,
    String? sitioWeb,
  }) async {
    try {
      final token = await obtenerToken();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios/$idNegocio'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_tipo_negocio': idTipoNegocio,
          'nombre': nombre,
          'descripcion': descripcion,
          'ubicacion': ubicacion,
          'tarifa': tarifa,
          'latitud': latitud,
          'longitud': longitud,
          'telefono': telefono,
          'sitio_web': sitioWeb,
        }),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ELIMINAR NEGOCIO
  Future<bool> eliminarNegocio(int idNegocio) async {
    try {
      final token = await obtenerToken();

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios/$idNegocio'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // OBTENER PLAN DEL NEGOCIO
  Future<Map<String, dynamic>?> obtenerPlan(int idNegocio) async {
    try {
      final token = await obtenerToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/negocios/plan/$idNegocio'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
