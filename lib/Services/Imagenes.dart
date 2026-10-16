
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'cliente_http.dart';

class ApiImagenes {
  final http.Client cliente = crearClienteHttp();

  Uri _url(String ruta) {
    return Uri.parse('${ApiConfig.baseUrl}$ruta');
  }

  // JWT solamente para Android/iOS
  Future<String?> _getToken() async {
    if (kIsWeb) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Autenticación según la plataforma
  Future<Map<String, String>?> _headers({
    bool json = false,
  }) async {
    if (kIsWeb) {
      // BrowserClient envía la cookie HttpOnly
      // cuando withCredentials está activado.
      return {
        if (json) 'Content-Type': 'application/json',
      };
    }

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  // OBTENER TODAS LAS IMÁGENES DE UN NEGOCIO
  Future<List<dynamic>> obtenerPorNegocio(
    int idNegocio,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return [];

      final response = await cliente.get(
        _url('/api/imagenes/negocio/$idNegocio'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }
      }

      debugPrint(
        'Error obtener imágenes: ${response.statusCode}',
      );
      return [];
    } catch (e) {
      debugPrint('Error obtener imágenes: $e');
      return [];
    }
  }

  // OBTENER UNA IMAGEN ESPECÍFICA
  Future<Map<String, dynamic>?> obtenerImagen(
    int idImagen,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;

      final response = await cliente.get(
        _url('/api/imagenes/$idImagen'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      debugPrint(
        'Error obtener imagen: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      debugPrint('Error obtener imagen: $e');
      return null;
    }
  }

  // OBTENER TODAS LAS IMÁGENES
  Future<List<dynamic>> obtenerImagenes() async {
    try {
      final headers = await _headers();
      if (headers == null) return [];

      final response = await cliente.get(
        _url('/api/imagenes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }
      }

      debugPrint(
        'Error obtener imágenes: ${response.statusCode}',
      );
      return [];
    } catch (e) {
      debugPrint('Error obtener imágenes: $e');
      return [];
    }
  }

  // CREAR IMAGEN
  Future<Map<String, dynamic>?> crearImagen({
    required int idNegocio,
    required String url,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return null;

      final response = await cliente.post(
        _url('/api/imagenes'),
        headers: headers,
        body: jsonEncode({
          'id_negocio': idNegocio,
          'url': url,
        }),
      );

      final data = jsonDecode(response.body);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error crear imagen: $e');
      return null;
    }
  }

  // ACTUALIZAR IMAGEN
  Future<Map<String, dynamic>?> actualizarImagen({
    required int idImagen,
    required int idNegocio,
    required String url,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return null;

      final response = await cliente.put(
        _url('/api/imagenes/$idImagen'),
        headers: headers,
        body: jsonEncode({
          'id_negocio': idNegocio,
          'url': url,
        }),
      );

      final data = jsonDecode(response.body);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error actualizar imagen: $e');
      return null;
    }
  }

  // ELIMINAR IMAGEN
  Future<bool> eliminarImagen(int idImagen) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      final response = await cliente.delete(
        _url('/api/imagenes/$idImagen'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error eliminar imagen: $e');
      return false;
    }
  }
}
