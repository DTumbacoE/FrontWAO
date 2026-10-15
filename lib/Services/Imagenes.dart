import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiImagenes {

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener todas las imágenes de un negocio
  Future<List<dynamic>> obtenerPorNegocio(int idNegocio) async {
    try {

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes/negocio/$idNegocio',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];

    } catch (e) {
      print('Error obtener imágenes: $e');
      return [];
    }
  }

  // Obtener una imagen específica
  Future<Map<String, dynamic>?> obtenerImagen(int idImagen) async {
    try {

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes/$idImagen',
        ),
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
      print('Error obtener imagen: $e');
      return null;
    }
  }

  // Obtener todas las imágenes
  Future<List<dynamic>> obtenerImagenes() async {
    try {

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];

    } catch (e) {
      print('Error obtener imágenes: $e');
      return [];
    }
  }

  // Crear imagen
  Future<Map<String, dynamic>?> crearImagen({
    required int idNegocio,
    required String url,
  }) async {
    try {

      final token = await _getToken();

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_negocio': idNegocio,
          'url': url,
        }),
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('Error crear imagen: $e');
      return null;
    }
  }

  // Actualizar imagen
  Future<Map<String, dynamic>?> actualizarImagen({
    required int idImagen,
    required int idNegocio,
    required String url,
  }) async {
    try {

      final token = await _getToken();

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes/$idImagen',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_negocio': idNegocio,
          'url': url,
        }),
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('Error actualizar imagen: $e');
      return null;
    }
  }

  // Eliminar imagen
  Future<bool> eliminarImagen(int idImagen) async {
    try {

      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/imagenes/$idImagen',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;

    } catch (e) {
      print('Error eliminar imagen: $e');
      return false;
    }
  }

}