import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiHorarios {

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtener horarios de un negocio
  Future<List<dynamic>> obtenerPorNegocio(int idNegocio) async {
    try {

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/horarios/negocio/$idNegocio',
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
      print('Error obtener horarios: $e');
      return [];
    }
  }

  // Obtener un horario específico
  Future<Map<String, dynamic>?> obtenerHorario(int idHorario) async {
    try {

      final token = await _getToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/horarios/$idHorario',
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
      print('Error obtener horario: $e');
      return null;
    }
  }

  // Crear horario
  Future<Map<String, dynamic>?> crearHorario({
    required int idNegocio,
    required String diaSemana,
    required String horaApertura,
    required String horaCierre,
  }) async {
    try {

      final token = await _getToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/horarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_negocio': idNegocio,
          'dia_semana': diaSemana,
          'hora_apertura': horaApertura,
          'hora_cierre': horaCierre,
        }),
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('Error crear horario: $e');
      return null;
    }
  }

  // Actualizar horario
  Future<Map<String, dynamic>?> actualizarHorario({
    required int idHorario,
    required String diaSemana,
    required String horaApertura,
    required String horaCierre,
  }) async {
    try {

      final token = await _getToken();

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/horarios/$idHorario',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'dia_semana': diaSemana,
          'hora_apertura': horaApertura,
          'hora_cierre': horaCierre,
        }),
      );

      return jsonDecode(response.body);

    } catch (e) {
      print('Error actualizar horario: $e');
      return null;
    }
  }

  // Eliminar horario
  Future<bool> eliminarHorario(int idHorario) async {
    try {

      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/horarios/$idHorario',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;

    } catch (e) {
      print('Error eliminar horario: $e');
      return false;
    }
  }
}