
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/Negocio.dart';
import '../Services/Imagenes.dart';
import '../Services/Plan.dart';
import '../Services/cloudinary_service.dart';

const Color _navy = Color(0xFF102C54);
const Color _background = Color(0xFFF5F8FC);
const Color _ink = Color(0xFF102C54);
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE0E8F2);
const Color _orange = Color(0xFFF5A623);
const Color _white = Colors.white;

class ImagenesWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool embedded;

  const ImagenesWeb({
    super.key,
    required this.usuario,
    this.embedded = false,
  });

  @override
  State<ImagenesWeb> createState() => _ImagenesWebState();
}

class _ImagenesWebState extends State<ImagenesWeb> {
  final ApiNegocio _api = ApiNegocio();
  final TextEditingController _buscar = TextEditingController();

  List<Map<String, dynamic>> _negocios = [];
  Map<String, dynamic>? _negocioSeleccionado;

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar.addListener(_actualizarBusqueda);
    _cargar();
  }

  void _actualizarBusqueda() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _buscar.removeListener(_actualizarBusqueda);
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final datos = await _api.misNegocios();

      if (!mounted) return;

      setState(() {
        _negocios = datos
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los negocios.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_negocioSeleccionado != null) {
      final negocio = _negocioSeleccionado!;
      final id = int.tryParse(
        '${negocio['id_negocio']}',
      );

      if (id != null) {
        return _GaleriaNegocioWeb(
          key: ValueKey(id),
          idNegocio: id,
          nombre: '${negocio['nombre'] ?? 'Negocio'}',
          embedded: widget.embedded,
          onBack: () {
            setState(() {
              _negocioSeleccionado = null;
            });
          },
        );
      }
    }

    final busqueda = _buscar.text.trim().toLowerCase();

    final filtrados = _negocios.where((negocio) {
      final texto =
          '${negocio['nombre'] ?? ''} ${negocio['ubicacion'] ?? ''}'
              .toLowerCase();

      return texto.contains(busqueda);
    }).toList();

    final contenido = LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1280,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ancho < 650 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezado(ancho < 650),

                  const SizedBox(height: 22),

                  TextField(
                    controller: _buscar,
                    style: const TextStyle(color: _ink),
                    decoration: _input(
                      'Buscar por nombre o ubicación...',
                      Icons.search_rounded,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Expanded(
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _orange,
                            ),
                          )
                        : _error != null
                            ? _mensajeVacio(
                                _error!,
                                Icons.error_outline_rounded,
                                _cargar,
                              )
                            : filtrados.isEmpty
                                ? _mensajeVacio(
                                    'No hay negocios para mostrar.',
                                    Icons.storefront_outlined,
                                    _cargar,
                                  )
                                : LayoutBuilder(
                                    builder: (context, c) {
                                      final columnas =
                                          c.maxWidth >= 1000
                                              ? 3
                                              : c.maxWidth >= 650
                                                  ? 2
                                                  : 1;

                                      return GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columnas,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          mainAxisExtent: 220,
                                        ),
                                        itemCount: filtrados.length,
                                        itemBuilder: (context, i) {
                                          return _tarjetaNegocio(
                                            filtrados[i],
                                          );
                                        },
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(
        color: _background,
        child: contenido,
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(child: contenido),
    );
  }

  Widget _encabezado(bool compacto) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galería de mis negocios',
          style: TextStyle(
            color: _ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Selecciona un establecimiento para administrar sus fotografías.',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
          ),
        ),
      ],
    );

    final actualizar = OutlinedButton.icon(
      onPressed: _cargando ? null : _cargar,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Actualizar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: _line),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 15,
        ),
      ),
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,
          const SizedBox(height: 12),
          actualizar,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),
        actualizar,
      ],
    );
  }

  Widget _tarjetaNegocio(
    Map<String, dynamic> negocio,
  ) {
    final id = int.tryParse(
      '${negocio['id_negocio']}',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: _orange,
              size: 25,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${negocio['nombre'] ?? 'Negocio'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: _muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${negocio['ubicacion'] ?? 'Sin ubicación'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: id == null
                  ? null
                  : () {
                      setState(() {
                        _negocioSeleccionado = negocio;
                      });
                    },
              icon: const Icon(
                Icons.photo_library_outlined,
              ),
              label: const Text('Administrar galería'),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _navy,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaleriaNegocioWeb extends StatefulWidget {
  final int idNegocio;
  final String nombre;
  final bool embedded;
  final VoidCallback? onBack;

  const _GaleriaNegocioWeb({
    super.key,
    required this.idNegocio,
    required this.nombre,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<_GaleriaNegocioWeb> createState() =>
      _GaleriaNegocioWebState();
}

class _GaleriaNegocioWebState
    extends State<_GaleriaNegocioWeb> {
  final ApiImagenes _imagenesApi = ApiImagenes();
  final ApiPlanes _planesApi = ApiPlanes();

  List<Map<String, dynamic>> _imagenes = [];
  Map<String, dynamic>? _plan;

  bool _cargando = true;
  bool _subiendo = false;
  bool _eliminando = false;
  String? _error;

  bool get _permite =>
      '${_plan?['permite_galeria'] ?? 0}' == '1';

  int get _max =>
      int.tryParse('${_plan?['max_imagenes'] ?? 0}') ?? 0;

  bool get _limite => _imagenes.length >= _max;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait<dynamic>([
        _planesApi.obtenerPlanNegocio(widget.idNegocio),
        _imagenesApi.obtenerPorNegocio(widget.idNegocio),
      ]);

      if (!mounted) return;

      setState(() {
        _plan = resultados[0] is Map
            ? Map<String, dynamic>.from(resultados[0] as Map)
            : null;

        _imagenes = (resultados[1] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo cargar la galería.';
        _cargando = false;
      });
    }
  }

  void _snack(
    String mensaje, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error
            ? const Color(0xFFB42318)
            : const Color(0xFF16876D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _subir() async {
    if (_subiendo || _eliminando || _cargando) return;

    if (!_permite) {
      _snack(
        'Tu plan no incluye galería de imágenes.',
        error: true,
      );
      return;
    }

    if (_limite) {
      _snack(
        'Has alcanzado el límite de imágenes de tu plan.',
        error: true,
      );
      return;
    }

    final seleccion = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (seleccion == null || !mounted) return;

    setState(() => _subiendo = true);

    try {
      final url = await CloudinaryService().subirImagen(
        seleccion,
      );

      if (url == null || url.isEmpty) {
        throw Exception(
          'No se obtuvo la URL de la imagen.',
        );
      }

      final resultado = await _imagenesApi.crearImagen(
        idNegocio: widget.idNegocio,
        url: url,
      );

      if (resultado == null ||
          resultado['success'] == false) {
        throw Exception(
          resultado?['message'] ??
              'No se pudo registrar la imagen.',
        );
      }

      await _cargar();

      _snack('Imagen subida correctamente.');
    } catch (e) {
      _snack(
        'No se pudo subir la imagen: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _subiendo = false);
      }
    }
  }

  Future<void> _eliminar(
    Map<String, dynamic> imagen,
  ) async {
    if (_eliminando || _subiendo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _white,
          surfaceTintColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Eliminar fotografía',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            '¿Deseas eliminar esta imagen de la galería?',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: _white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    final id = int.tryParse(
      '${imagen['id_imagen']}',
    );

    if (id == null) {
      _snack(
        'Identificador de imagen inválido.',
        error: true,
      );
      return;
    }

    setState(() => _eliminando = true);

    try {
      final eliminado = await _imagenesApi.eliminarImagen(id);

      if (!eliminado) {
        throw Exception('La API rechazó la eliminación.');
      }

      await _cargar();

      _snack('Imagen eliminada correctamente.');
    } catch (e) {
      _snack(
        'No se pudo eliminar la imagen.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _eliminando = false);
      }
    }
  }

  void _ver(Map<String, dynamic> imagen) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: _white,
          surfaceTintColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
              maxHeight: 740,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    8,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vista previa',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () {
                          Navigator.pop(ctx);
                          _eliminar(imagen);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFB42318),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.network(
                      '${imagen['url']}',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: _muted,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maximo = _max;

    final progreso = maximo > 0
        ? (_imagenes.length / maximo).clamp(0.0, 1.0)
        : 0.0;

    final contenido = LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final compacto = ancho < 780;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1280,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                ancho < 650 ? 16 : 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezadoGaleria(compacto),

                  const SizedBox(height: 22),

                  if (!_cargando && _plan != null)
                    _resumenPlan(progreso),

                  if (!_cargando && _plan != null)
                    const SizedBox(height: 20),

                  if (_subiendo)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: LinearProgressIndicator(
                        color: _orange,
                      ),
                    ),

                  Expanded(
                    child: _cargando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: _orange,
                            ),
                          )
                        : _error != null
                            ? _mensajeVacio(
                                _error!,
                                Icons.error_outline,
                                _cargar,
                              )
                            : !_permite
                                ? _mensajeVacio(
                                    'Tu plan no incluye galería de imágenes.',
                                    Icons.lock_outline_rounded,
                                    _cargar,
                                  )
                                : _imagenes.isEmpty
                                    ? _mensajeVacio(
                                        'Todavía no has subido fotografías.',
                                        Icons.photo_library_outlined,
                                        _subir,
                                      )
                                    : LayoutBuilder(
                                        builder: (context, c) {
                                          final columnas =
                                              c.maxWidth >= 1050
                                                  ? 5
                                                  : c.maxWidth >= 750
                                                      ? 4
                                                      : c.maxWidth >= 480
                                                          ? 3
                                                          : 2;

                                          return GridView.builder(
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: columnas,
                                              crossAxisSpacing: 14,
                                              mainAxisSpacing: 14,
                                            ),
                                            itemCount: _imagenes.length,
                                            itemBuilder: (context, i) {
                                              return _tarjetaImagen(
                                                _imagenes[i],
                                              );
                                            },
                                          );
                                        },
                                      ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(
        color: _background,
        child: contenido,
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(child: contenido),
    );
  }

  Widget _encabezadoGaleria(bool compacto) {
    final titulo = Row(
      children: [
        IconButton(
          onPressed: widget.onBack ??
              () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _navy,
          ),
          tooltip: 'Volver a mis negocios',
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Galería',
                style: TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final acciones = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _cargando ? null : _cargar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Actualizar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,
            side: const BorderSide(color: _line),
          ),
        ),
        FilledButton.icon(
          onPressed: _subiendo || _cargando || _eliminando
              ? null
              : _subir,
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
          ),
          label: Text(
            _subiendo ? 'Subiendo...' : 'Subir imagen',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: _navy,
          ),
        ),
      ],
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,
          const SizedBox(height: 12),
          acciones,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),
        acciones,
      ],
    );
  }

  Widget _resumenPlan(double progreso) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: _orange,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: ${_plan?['nombre'] ?? 'Sin plan'}',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_imagenes.length} de $_max imágenes utilizadas',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progreso * 100).round()}%',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: _line,
              color: _orange,
            ),
          ),

          if (!_permite || _limite)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                !_permite
                    ? 'Este plan no permite subir imágenes.'
                    : 'Has alcanzado el límite de imágenes de tu plan.',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaImagen(
    Map<String, dynamic> imagen,
  ) {
    return Container(
      decoration: _decoracionTarjeta(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: () => _ver(imagen),
              child: Image.network(
                '${imagen['url']}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const ColoredBox(
                    color: Color(0xFFF0F4F9),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: _muted,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Eliminar fotografía',
                onPressed: _eliminando || _subiendo
                    ? null
                    : () => _eliminar(imagen),
                style: IconButton.styleFrom(
                  backgroundColor: _white,
                  foregroundColor: const Color(0xFFB42318),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _decoracionTarjeta() {
  return BoxDecoration(
    color: _white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(
        color: Color(0x07102C54),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}

InputDecoration _input(
  String hint,
  IconData icono,
) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: _muted,
      fontSize: 13,
    ),
    prefixIcon: Icon(
      icono,
      color: _muted,
    ),
    filled: true,
    fillColor: _white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 17,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: _orange,
        width: 1.5,
      ),
    ),
  );
}

Widget _mensajeVacio(
  String mensaje,
  IconData icono,
  VoidCallback accion,
) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icono,
          color: _muted,
          size: 52,
        ),
        const SizedBox(height: 13),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: accion,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar / actualizar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,
            side: const BorderSide(color: _line),
          ),
        ),
      ],
    ),
  );
}
