import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'cliente_http.dart';

class CloudinaryService {
  // No se envían credenciales de Cloudinary al dispositivo.
  Future<Map<String, dynamic>> subirImagen(XFile imagen, int idNegocio) async {
    final bytes = await imagen.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('La imagen debe ocupar entre 1 byte y 5 MB.');
    }
    final client = crearClienteHttp();
    try {
      final request = http.MultipartRequest('POST',
        Uri.parse('${ApiConfig.baseUrl}/api/imagenes/subir'));
      request.fields['id_negocio'] = idNegocio.toString();
      request.files.add(http.MultipartFile.fromBytes('imagen', bytes,
        filename: imagen.name));
      if (!kIsWeb) {
        final token = (await SharedPreferences.getInstance()).getString('token');
        if (token == null || token.isEmpty) throw Exception('Sesión no disponible');
        request.headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.Response.fromStream(await client.send(request));
      final data = jsonDecode(response.body);
      if (response.statusCode != 201 || data is! Map || data['success'] != true) {
        throw Exception(data is Map ? (data['message'] ?? 'Error de subida') : 'Error de subida');
      }
      return Map<String, dynamic>.from(data);
    } finally {
      client.close();
    }
  }
}
