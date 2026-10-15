import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String cloudName = 'dly7mdtpb';
  final String uploadPreset = 'imagenes';
  final Dio dio = Dio();

  /// Compatible con Android y Flutter Web: XFile funciona en ambas plataformas.
  Future<String?> subirImagen(XFile imagen) async {
    try {
      final bytes = await imagen.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw Exception('Imagen vacía o superior a 10 MB');
      }
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: imagen.name),
        'upload_preset': uploadPreset,
      });
      final response = await dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        data: formData,
      );
      return response.data?['secure_url'] as String?;
    } on DioException catch (e) {
      print('Cloudinary STATUS: ${e.response?.statusCode}');
      print('Cloudinary DATA: ${e.response?.data}');
      return null;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }
}
