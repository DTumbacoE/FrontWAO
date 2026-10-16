
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'cliente_http.dart';

class ApiHorarios {
  final http.Client cliente = crearClienteHttp();

  Uri _url(String ruta) {
    return Uri.parse('${ApiConfig.baseUrl}$ruta');
  }

  // JWT únicamente para Android/iOS
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
      // mediante withCredentials = true.
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

  // OBTENER HORARIOS DE UN NEGOCIO
  Future<List<dynamic>> obtenerPorNegocio(
    int idNegocio,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return [];

      final response = await cliente.get(
        _url('/api/horarios/negocio/$idNegocio'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }
      }

      debugPrint(
        'Error obtener horarios: ${response.statusCode}',
      );

      return [];
    } catch (e) {
      debugPrint('Error obtener horarios: $e');
      return [];
    }
  }

  // OBTENER UN HORARIO ESPECÍFICO
  Future<Map<String, dynamic>?> obtenerHorario(
    int idHorario,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;

      final response = await cliente.get(
        _url('/api/horarios/$idHorario'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      debugPrint(
        'Error obtener horario: ${response.statusCode}',
      );

      return null;
    } catch (e) {
      debugPrint('Error obtener horario: $e');
      return null;
    }
  }

  // CREAR HORARIO
  Future<Map<String, dynamic>?> crearHorario({
    required int idNegocio,
    required String diaSemana,
    required String horaApertura,
    required String horaCierre,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return null;

      final response = await cliente.post(
        _url('/api/horarios'),
        headers: headers,
        body: jsonEncode({
          'id_negocio': idNegocio,
          'dia_semana': diaSemana,
          'hora_apertura': horaApertura,
          'hora_cierre': horaCierre,
        }),
      );

      final data = jsonDecode(response.body);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error crear horario: $e');
      return null;
    }
  }

  // ACTUALIZAR HORARIO
  Future<Map<String, dynamic>?> actualizarHorario({
    required int idHorario,
    required String diaSemana,
    required String horaApertura,
    required String horaCierre,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return null;

      final response = await cliente.put(
        _url('/api/horarios/$idHorario'),
        headers: headers,
        body: jsonEncode({
          'dia_semana': diaSemana,
          'hora_apertura': horaApertura,
          'hora_cierre': horaCierre,
        }),
      );

      final data = jsonDecode(response.body);

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (e) {
      debugPrint('Error actualizar horario: $e');
      return null;
    }
  }

  // ELIMINAR HORARIO
  Future<bool> eliminarHorario(
    int idHorario,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      final response = await cliente.delete(
        _url('/api/horarios/$idHorario'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error eliminar horario: $e');
      return false;
    }
  }
}
