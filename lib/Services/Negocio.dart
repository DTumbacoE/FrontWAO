
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'cliente_http.dart';

class ApiNegocio {
  final http.Client cliente = crearClienteHttp();

  Uri _url(String ruta) => Uri.parse('${ApiConfig.baseUrl}$ruta');

  Future<String?> obtenerToken() async {
    if (kIsWeb) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>?> _headers({
    bool json = false,
  }) async {
    if (kIsWeb) {
      return {
        if (json) 'Content-Type': 'application/json',
      };
    }

    final token = await obtenerToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
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
      final headers = await _headers(json: true);
      if (headers == null) return false;

      final response = await cliente.post(
        _url('/api/negocios'),
        headers: headers,
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
    } catch (e) {
      return false;
    }
  }

  // OBTENER TODOS LOS NEGOCIOS
  Future<List<dynamic>> obtenerTodos() async {
    try {
      final headers = await _headers();
      if (headers == null) return [];

      final response = await cliente.get(
        _url('/api/negocios'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // MIS NEGOCIOS
  Future<List<dynamic>> misNegocios() async {
    try {
      final headers = await _headers();
      if (headers == null) return [];

      final response = await cliente.get(
        _url('/api/negocios/mis-negocios'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // OBTENER NEGOCIO POR ID
  Future<Map<String, dynamic>?> obtenerNegocio(
    int idNegocio,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;

      final response = await cliente.get(
        _url('/api/negocios/$idNegocio'),
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
      final headers = await _headers(json: true);
      if (headers == null) return false;

      final response = await cliente.put(
        _url('/api/negocios/$idNegocio'),
        headers: headers,
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
    } catch (e) {
      return false;
    }
  }

  // ELIMINAR NEGOCIO
  Future<bool> eliminarNegocio(int idNegocio) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      final response = await cliente.delete(
        _url('/api/negocios/$idNegocio'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // OBTENER PLAN DEL NEGOCIO
  Future<Map<String, dynamic>?> obtenerPlan(
    int idNegocio,
  ) async {
    try {
      final headers = await _headers();
      if (headers == null) return null;

      final response = await cliente.get(
        _url('/api/negocios/plan/$idNegocio'),
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
      return null;
    }
  }
}
