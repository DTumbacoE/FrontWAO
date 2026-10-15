import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/Negocio.dart';
import '../Services/Imagenes.dart';
import '../Services/Plan.dart';
import '../Services/cloudinary_service.dart';

const _navy = Color(0xFF081529);
const _panel = Color(0xFF102747);
const _orange = Color(0xFFF5A623);


class ImagenesWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool embedded;
  const ImagenesWeb({super.key, required this.usuario, this.embedded = false});
  @override
  State<ImagenesWeb> createState() => _ImagenesWebState();
}

class _ImagenesWebState extends State<ImagenesWeb> {
  final _api = ApiNegocio();
  final _buscar = TextEditingController();
  List<Map<String, dynamic>> _negocios = [];
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _negocioSeleccionado;

  @override
  void initState() {
    super.initState();
    _buscar.addListener(_refresh);
    _cargar();
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _buscar.removeListener(_refresh);
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final datos = await _api.misNegocios();
      if (!mounted) return;
      setState(() {
        _negocios = datos.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _negocios.where((n) =>
      '${n['nombre'] ?? ''} ${n['ubicacion'] ?? ''}'.toLowerCase().contains(_buscar.text.toLowerCase())).toList();
    if (_negocioSeleccionado != null) {
      final negocio = _negocioSeleccionado!;
      final id = int.tryParse('${negocio['id_negocio']}');
      if (id != null) {
        return _GaleriaNegocioWeb(
          key: ValueKey(id),
          idNegocio: id,
          nombre: '${negocio['nombre'] ?? 'Negocio'}',
          embedded: widget.embedded,
          onBack: () => setState(() => _negocioSeleccionado = null),
        );
      }
    }
    final content = Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (!widget.embedded) IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Galería de mis negocios', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold))),
              OutlinedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
            ]),
            const SizedBox(height: 8),
            const Text('Selecciona un establecimiento para administrar sus fotografías.', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            SizedBox(width: 420, child: TextField(controller: _buscar,
              style: const TextStyle(color: Colors.white),
              decoration: _input('Buscar negocio', Icons.search))),
            const SizedBox(height: 20),
            Expanded(child: _cargando ? const Center(child: CircularProgressIndicator(color: _orange))
              : _error != null ? _message('No se pudieron cargar los negocios', _cargar)
              : filtrados.isEmpty ? _message('No hay negocios para mostrar', _cargar)
              : LayoutBuilder(builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 1000 ? 3 : constraints.maxWidth >= 650 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols,
                      crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 205),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) {
                      final negocio = filtrados[i];
                      return _businessCard(negocio);
                    },
                  );
                })),
          ],
        ))));
    return widget.embedded ? content : Scaffold(backgroundColor: _navy, body: SafeArea(child: content));
  }

  Widget _businessCard(Map<String, dynamic> negocio) {
    final id = int.tryParse('${negocio['id_negocio']}');
    return Card(color: _panel, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront, color: _orange, size: 30),
          const SizedBox(height: 10),
          Text('${negocio['nombre'] ?? 'Negocio'}', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('${negocio['ubicacion'] ?? 'Sin ubicación'}', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: _navy),
            onPressed: id == null ? null : () => setState(() => _negocioSeleccionado = negocio),
            icon: const Icon(Icons.photo_library_outlined), label: const Text('Administrar galería'))),
        ],
      )));
  }
}

class _GaleriaNegocioWeb extends StatefulWidget {
  final int idNegocio;
  final String nombre;
  final bool embedded;
  final VoidCallback? onBack;
  const _GaleriaNegocioWeb({super.key, required this.idNegocio, required this.nombre, this.embedded = false, this.onBack});
  @override
  State<_GaleriaNegocioWeb> createState() => _GaleriaNegocioWebState();
}

class _GaleriaNegocioWebState extends State<_GaleriaNegocioWeb> {
  final _imagenesApi = ApiImagenes();
  final _planesApi = ApiPlanes();
  List<Map<String, dynamic>> _imagenes = [];
  Map<String, dynamic>? _plan;
  bool _cargando = true;
  bool _subiendo = false;
  String? _error;

  bool get _permite => '${_plan?['permite_galeria'] ?? 0}' == '1';
  int get _max => int.tryParse('${_plan?['max_imagenes'] ?? 0}') ?? 0;
  bool get _limite => _imagenes.length >= _max;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        _planesApi.obtenerPlanNegocio(widget.idNegocio),
        _imagenesApi.obtenerPorNegocio(widget.idNegocio),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] is Map ? Map<String, dynamic>.from(results[0] as Map) : null;
        _imagenes = (results[1] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _cargando = false; });
    }
  }

  void _snack(String mensaje) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _subir() async {
    if (!_permite) { _snack('Tu plan no incluye galería de imágenes.'); return; }
    if (_limite) { _snack('Has alcanzado el límite de imágenes de tu plan.'); return; }
    final seleccion = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (seleccion == null) return;
    if (!mounted) return;
    setState(() => _subiendo = true);
    try {
      final url = await CloudinaryService().subirImagen(seleccion);
      if (url == null || url.isEmpty) throw Exception('Cloudinary no devolvió una URL');
      await _imagenesApi.crearImagen(idNegocio: widget.idNegocio, url: url);
      await _cargar();
      _snack('Imagen subida correctamente');
    } catch (e) {
      _snack('No se pudo subir la imagen: $e');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _eliminar(Map<String, dynamic> imagen) async {
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Eliminar fotografía'),
      content: const Text('¿Deseas eliminar esta imagen de la galería?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirmar != true) return;
    try {
      final id = int.tryParse('${imagen['id_imagen']}');
      if (id == null) throw Exception('ID de imagen inválido');
      final ok = await _imagenesApi.eliminarImagen(id);
      if (ok != true) throw Exception('La API rechazó la eliminación');
      await _cargar();
      _snack('Imagen eliminada');
    } catch (e) { _snack('Error al eliminar: $e'); }
  }

  void _ver(Map<String, dynamic> imagen) {
    showDialog<void>(context: context, builder: (context) => Dialog(
      backgroundColor: _navy,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 740),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const SizedBox(width: 16),
            const Expanded(child: Text('Vista previa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            IconButton(onPressed: () { Navigator.pop(context); _eliminar(imagen); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
          ]),
          Flexible(child: InteractiveViewer(child: Image.network('${imagen['url']}', fit: BoxFit.contain))),
          const SizedBox(height: 14),
        ])),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final max = _max;
    final progreso = max > 0 ? (_imagenes.length / max).clamp(0.0, 1.0) : 0.0;
    final content = Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1280),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(onPressed: widget.onBack ?? () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Galería', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(widget.nombre, style: const TextStyle(color: Colors.white60)),
            ])),
            OutlinedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
            const SizedBox(width: 12),
            FilledButton.icon(onPressed: _subiendo || _cargando ? null : _subir,
              style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: _navy),
              icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Subir imagen')),
          ]),
          const SizedBox(height: 20),
          if (!_cargando && _plan != null) Card(color: _panel, child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan: ${_plan?['nombre'] ?? 'Sin plan'}  •  ${_imagenes.length} / $max imágenes',
                style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progreso, color: _orange, backgroundColor: Colors.white12),
              if (!_permite) const Padding(padding: EdgeInsets.only(top: 10),
                child: Text('Este plan no permite subir imágenes.', style: TextStyle(color: Colors.orangeAccent))),
              if (_permite && _limite) const Padding(padding: EdgeInsets.only(top: 10),
                child: Text('Límite de imágenes alcanzado.', style: TextStyle(color: Colors.orangeAccent))),
            ],
          ))),
          const SizedBox(height: 18),
          if (_subiendo) const LinearProgressIndicator(color: _orange),
          Expanded(child: _cargando ? const Center(child: CircularProgressIndicator(color: _orange))
            : _error != null ? _message('Error al cargar galería', _cargar)
            : !_permite ? _message('Tu plan no incluye galería de imágenes', _cargar)
            : _imagenes.isEmpty ? _message('Todavía no has subido fotografías', _subir)
            : LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 1050 ? 5 : c.maxWidth >= 750 ? 4 : c.maxWidth >= 480 ? 3 : 2;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14),
                  itemCount: _imagenes.length,
                  itemBuilder: (context, i) {
                    final imagen = _imagenes[i];
                    return InkWell(onTap: () => _ver(imagen), child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(fit: StackFit.expand, children: [
                        Image.network('${imagen['url']}', fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(color: _panel,
                            child: Icon(Icons.broken_image_outlined, color: Colors.white38))),
                        Positioned(top: 6, right: 6, child: IconButton.filledTonal(
                          onPressed: () => _eliminar(imagen),
                          icon: const Icon(Icons.delete_outline, size: 18))),
                      ]),
                    ));
                  },
                );
              })),
        ],
      )),
    ));
    return widget.embedded ? content : Scaffold(backgroundColor: _navy, body: SafeArea(child: content));
  }
}

InputDecoration _input(String hint, IconData icon) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
  prefixIcon: Icon(icon, color: Colors.white54),
  filled: true, fillColor: _panel,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
);

Widget _message(String message, VoidCallback action) => Center(child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(Icons.photo_library_outlined, color: Colors.white38, size: 55),
    const SizedBox(height: 12),
    Text(message, style: const TextStyle(color: Colors.white70)),
    const SizedBox(height: 14),
    OutlinedButton(onPressed: action, child: const Text('Reintentar / actualizar')),
  ],
));
