import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:http_parser/http_parser.dart';
class ApiUsuario {
  Uri _url(String ruta) => Uri.parse('${ApiConfig.baseUrl}$ruta');

  Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>?> _headers({bool json = false}) async {
    final token = await obtenerToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _resultado(http.Response response) {
    Map<String, dynamic> data = {};
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map) data = Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return {
      ...data,
      'success':
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] != false,
      'statusCode': response.statusCode,
      'message':
          data['message']?.toString() ??
          (response.statusCode >= 200 && response.statusCode < 300
              ? 'Operación realizada'
              : 'No se pudo completar la solicitud'),
    };
  }

  Map<String, dynamic> _errorConexion() => {
    'success': false,
    'statusCode': 0,
    'message': 'No se pudo conectar con el servidor',
  };

  Future<void> _guardarUsuario(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final actualTexto = prefs.getString('usuario');
    Map<String, dynamic> actual = {};
    if (actualTexto != null) {
      try {
        final decodificado = jsonDecode(actualTexto);
        if (decodificado is Map)
          actual = Map<String, dynamic>.from(decodificado);
      } catch (_) {}
    }
    await prefs.setString('usuario', jsonEncode({...actual, ...usuario}));
  }

  Future<Map<String, dynamic>?> login(String correo, String password) async {
    try {
      final response = await http.post(
        _url('/api/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo.trim().toLowerCase(),
          'password': password,
        }),
      );
      if (response.statusCode != 200) return null;
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      if (data['token'] is! String || data['usuario'] is! Map) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'] as String);
      await prefs.setString('usuario', jsonEncode(data['usuario']));
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<bool> registrarUsuario({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String direccion,
    required String password,
    required int idRol,
  }) async {
    final resultado = await registrarUsuarioDetallado(
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      telefono: telefono,
      direccion: direccion,
      password: password,
      idRol: idRol,
    );
    return resultado['success'] == true;
  }

  Future<Map<String, dynamic>> registrarUsuarioDetallado({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String direccion,
    required String password,
    required int idRol,
  }) async {
    try {
      final response = await http.post(
        _url('/api/usuarios/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'correo': correo.trim().toLowerCase(),
          'telefono': telefono.trim(),
          'direccion': direccion.trim(),
          'password': password,
          'id_rol': idRol,
        }),
      );
      return _resultado(response);
    } catch (_) {
      return _errorConexion();
    }
  }

  Future<Map<String, dynamic>?> obtenerPerfil() async {
    try {
      final headers = await _headers();
      if (headers == null) return null;
      final response = await http.get(
        _url('/api/usuarios/perfil'),
        headers: headers,
      );
      if (response.statusCode != 200) return null;
      final usuario = Map<String, dynamic>.from(jsonDecode(response.body));
      await _guardarUsuario(usuario);
      return usuario;
    } catch (_) {
      return null;
    }
  }

  // Solo se permiten estos cuatro campos. Correo y rol nunca se envían.
  Future<Map<String, dynamic>> editarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
    required String direccion,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return _sinSesion();
      final response = await http.put(
        _url('/api/perfil'),
        headers: headers,
        body: jsonEncode({
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'telefono': telefono.trim(),
          'direccion': direccion.trim(),
        }),
      );
      final resultado = _resultado(response);
      if (resultado['success'] == true && resultado['usuario'] is Map) {
        await _guardarUsuario(Map<String, dynamic>.from(resultado['usuario']));
      }
      return resultado;
    } catch (_) {
      return _errorConexion();
    }
  }

  Future<Map<String, dynamic>> cambiarContrasena({
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    try {
      final headers = await _headers(json: true);
      if (headers == null) return _sinSesion();
      final response = await http.put(
        _url('/api/perfil/cambiar-contrasena'),
        headers: headers,
        body: jsonEncode({
          'contrasenaActual': contrasenaActual,
          'contrasenaNueva': contrasenaNueva,
        }),
      );
      return _resultado(response);
    } catch (_) {
      return _errorConexion();
    }
  }

  // Compatible con Flutter Web y móvil: enviar bytes seleccionados con file_picker.
  Future<Map<String, dynamic>> subirFotoPerfil({
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) return _sinSesion();
      final request = http.MultipartRequest(
        'POST',
        _url('/api/perfil/foto-perfil'),
      );
      request.headers.addAll(headers);

      final extension = nombreArchivo.split('.').last.toLowerCase();

      String tipoMime;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          tipoMime = 'jpeg';
          break;
        case 'png':
          tipoMime = 'png';
          break;
        case 'webp':
          tipoMime = 'webp';
          break;
        default:
          throw Exception('Formato de imagen no permitido');
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          bytes,
          filename: nombreArchivo,
          contentType: MediaType('image', tipoMime),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final resultado = _resultado(response);
      if (resultado['success'] == true) {
        await _guardarUsuario({
          'foto_perfil_url': resultado['foto_perfil_url'],
        });
      }
      return resultado;
    } catch (_) {
      return _errorConexion();
    }
  }

  Future<Map<String, dynamic>> eliminarFotoPerfil() async {
    try {
      final headers = await _headers();
      if (headers == null) return _sinSesion();
      final response = await http.delete(
        _url('/api/perfil/foto-perfil'),
        headers: headers,
      );
      final resultado = _resultado(response);
      if (resultado['success'] == true) {
        await _guardarUsuario({'foto_perfil_url': null});
      }
      return resultado;
    } catch (_) {
      return _errorConexion();
    }
  }

  Map<String, dynamic> _sinSesion() => {
    'success': false,
    'statusCode': 401,
    'message': 'Debes iniciar sesión nuevamente',
  };

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }

  Future<bool> estaLogueado() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> validarToken() async {
    try {
      final headers = await _headers();
      if (headers == null) return false;
      final response = await http.get(
        _url('/api/usuarios/validar-token'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> reenviarVerificacion(String correo) async {
    try {
      final response = await http.post(
        _url('/api/usuarios/reenviar-verificacion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo.trim().toLowerCase()}),
      );
      return _resultado(response);
    } catch (_) {
      return _errorConexion();
    }
  }
}
