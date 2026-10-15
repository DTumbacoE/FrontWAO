
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiRecuperacion {

  // Enviar código de recuperación al correo electrónico
  Future<Map<String, dynamic>> solicitarCodigo(String correo) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/recuperacion/recuperar-contrasena',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
        }),
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': data is Map
            ? (data['message']?.toString() ?? 'Solicitud procesada')
            : 'Solicitud procesada',
      };
    } catch (e) {
      print('Error al solicitar código: $e');

      return {
        'success': false,
        'statusCode': 0,
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }

  // Verificar el código de 6 dígitos recibido por correo
  Future<Map<String, dynamic>> verificarCodigo(
    String correo,
    String codigo,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/recuperacion/verificar-codigo',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
          'codigo': codigo.trim(),
        }),
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': data is Map
            ? (data['message']?.toString() ?? 'Error al verificar código')
            : 'Error al verificar código',
        'resetToken': data is Map ? data['resetToken'] : null,
      };
    } catch (e) {
      print('Error al verificar código: $e');

      return {
        'success': false,
        'statusCode': 0,
        'message': 'No se pudo conectar con el servidor',
        'resetToken': null,
      };
    }
  }

  // Restablecer contraseña después de verificar el código
  Future<Map<String, dynamic>> restablecerContrasena(
    String resetToken,
    String nuevaContrasena,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/recuperacion/restablecer-contrasena',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resetToken': resetToken,
          'nuevaContrasena': nuevaContrasena,
        }),
      );

      dynamic data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': data is Map
            ? (data['message']?.toString() ?? 'Error al cambiar contraseña')
            : 'Error al cambiar contraseña',
      };
    } catch (e) {
      print('Error al restablecer contraseña: $e');

      return {
        'success': false,
        'statusCode': 0,
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }
}
