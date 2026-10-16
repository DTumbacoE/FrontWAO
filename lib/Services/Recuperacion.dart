
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiRecuperacion {
  Uri _url(String ruta) {
    return Uri.parse('${ApiConfig.baseUrl}$ruta');
  }

  Map<String, dynamic> _procesarRespuesta(
    http.Response response, {
    bool incluirResetToken = false,
  }) {
    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Respuesta no JSON
    }

    final exitoso =
        response.statusCode == 200 &&
        data['success'] != false;

    return {
      'success': exitoso,
      'statusCode': response.statusCode,
      'message': data['message']?.toString() ??
          (exitoso
              ? 'Solicitud procesada'
              : 'No se pudo completar la solicitud'),
      if (incluirResetToken)
        'resetToken': exitoso ? data['resetToken'] : null,
    };
  }

  Map<String, dynamic> _errorConexion({
    bool incluirResetToken = false,
  }) {
    return {
      'success': false,
      'statusCode': 0,
      'message': 'No se pudo conectar con el servidor',
      if (incluirResetToken) 'resetToken': null,
    };
  }

  // SOLICITAR CÓDIGO DE RECUPERACIÓN
  Future<Map<String, dynamic>> solicitarCodigo(
    String correo,
  ) async {
    try {
      final response = await http.post(
        _url('/api/recuperacion/recuperar-contrasena'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
        }),
      );

      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error al solicitar código: $e');
      return _errorConexion();
    }
  }

  // VERIFICAR CÓDIGO
  Future<Map<String, dynamic>> verificarCodigo(
    String correo,
    String codigo,
  ) async {
    try {
      final response = await http.post(
        _url('/api/recuperacion/verificar-codigo'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
          'codigo': codigo.trim(),
        }),
      );

      return _procesarRespuesta(
        response,
        incluirResetToken: true,
      );
    } catch (e) {
      debugPrint('Error al verificar código: $e');

      return _errorConexion(
        incluirResetToken: true,
      );
    }
  }

  // RESTABLECER CONTRASEÑA
  Future<Map<String, dynamic>> restablecerContrasena(
    String resetToken,
    String nuevaContrasena,
  ) async {
    try {
      final response = await http.post(
        _url('/api/recuperacion/restablecer-contrasena'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'resetToken': resetToken,
          'nuevaContrasena': nuevaContrasena,
        }),
      );

      return _procesarRespuesta(response);
    } catch (e) {
      debugPrint('Error al restablecer contraseña: $e');
      return _errorConexion();
    }
  }
}
