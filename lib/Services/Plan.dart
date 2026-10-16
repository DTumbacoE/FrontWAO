
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'cliente_http.dart';

class ApiPlanes {
  final http.Client cliente = crearClienteHttp();

  Uri _url(String ruta) {
    return Uri.parse('${ApiConfig.baseUrl}$ruta');
  }

  // Obtener JWT únicamente en Android/iOS
  Future<String?> _getToken() async {
    if (kIsWeb) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Configurar autenticación según plataforma
  Future<Map<String, String>?> _headers() async {
    if (kIsWeb) {
      // BrowserClient envía la cookie HttpOnly automáticamente
      return {
        'Content-Type': 'application/json',
      };
    }

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // OBTENER PLAN DEL NEGOCIO
  Future<Map<String, dynamic>?> obtenerPlanNegocio(
    int idNegocio,
  ) async {
    try {
      final headers = await _headers();

      if (headers == null) {
        return null;
      }

      final response = await cliente.get(
        _url('/api/planes/negocio/$idNegocio'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return null;
    } catch (e) {
      print('Error al obtener plan del negocio: $e');
      return null;
    }
  }
}
