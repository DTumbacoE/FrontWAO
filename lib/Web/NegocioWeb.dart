
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Services/Negocio.dart';
import 'MiPlanWeb.dart';
import 'HorariosWeb.dart';
import 'AgregarNegocioWeb.dart';

const Color _navy = Color(0xFF102C54);
const Color _background = Color(0xFFF5F8FC);
const Color _ink = Color(0xFF102C54);
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE0E8F2);
const Color _orange = Color(0xFFF5A623);
const Color _white = Colors.white;

const LatLng _initialCenter = LatLng(-2.19616, -79.88621);

const String _mapStyle = '''
[
  {"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"all","stylers":[{"visibility":"off"}]}
]
''';

class NegociosWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final bool embedded;

  const NegociosWeb({
    super.key,
    required this.usuario,
    this.embedded = false,
  });

  @override
  State<NegociosWeb> createState() => _NegociosWebState();
}

class _NegociosWebState extends State<NegociosWeb> {
  final ApiNegocio _api = ApiNegocio();
  final TextEditingController _buscar = TextEditingController();

  GoogleMapController? _mapController;

  List<Map<String, dynamic>> _negocios = [];

  bool _cargando = true;
  String? _error;
  String _categoria = 'Todas';

  Map<String, dynamic>? _negocioHorarios;
  int? _idNegocioPlan;

  @override
  void initState() {
    super.initState();
    _buscar.addListener(_actualizarBusqueda);
    _cargarNegocios();
  }

  void _actualizarBusqueda() {
    if (!mounted) return;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centrarEnNegocios();
    });
  }

  @override
  void dispose() {
    _buscar.removeListener(_actualizarBusqueda);
    _buscar.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _cargarNegocios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await _api.misNegocios();

      final negocios = respuesta
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (!mounted) return;

      setState(() {
        _negocios = negocios;
        _cargando = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centrarEnNegocios();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los negocios.';
      });
    }
  }

  LatLng? _coordenadas(Map<String, dynamic> negocio) {
    final lat = double.tryParse(
      '${negocio['latitud'] ?? ''}',
    );

    final lng = double.tryParse(
      '${negocio['longitud'] ?? ''}',
    );

    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }

    return LatLng(lat, lng);
  }

  String _categoriaDe(Map<String, dynamic> negocio) {
    final tipo = negocio['tipo_negocio'];

    final nombre = negocio['tipo_nombre'] ??
        negocio['tipo_label'] ??
        (tipo is Map ? tipo['nombre'] : null);

    return (nombre ?? 'Negocio').toString();
  }

  List<Map<String, dynamic>> get _filtrados {
    final texto = _buscar.text.trim().toLowerCase();

    return _negocios.where((negocio) {
      final coincideCategoria = _categoria == 'Todas' ||
          _categoriaDe(negocio) == _categoria;

      final contenido =
          '${negocio['nombre'] ?? ''} '
          '${negocio['ubicacion'] ?? ''} '
          '${negocio['descripcion'] ?? ''}'
              .toLowerCase();

      return coincideCategoria && contenido.contains(texto);
    }).toList();
  }

  Set<Marker> get _marcadores {
    final resultado = <Marker>{};

    for (final negocio in _filtrados) {
      final punto = _coordenadas(negocio);

      if (punto == null) continue;

      resultado.add(
        Marker(
          markerId: MarkerId(
            'negocio_${negocio['id_negocio']}',
          ),
          position: punto,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${negocio['nombre'] ?? 'Negocio'}',
            snippet: '${negocio['ubicacion'] ?? ''}',
          ),
        ),
      );
    }

    return resultado;
  }

  void _centrarEnNegocios() {
    if (!mounted || _mapController == null) return;

    final puntos = _marcadores
        .map((marker) => marker.position)
        .toList();

    if (puntos.isEmpty) return;

    if (puntos.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(puntos.first, 15),
      );
      return;
    }

    double sur = puntos.first.latitude;
    double norte = sur;
    double oeste = puntos.first.longitude;
    double este = oeste;

    for (final punto in puntos) {
      if (punto.latitude < sur) sur = punto.latitude;
      if (punto.latitude > norte) norte = punto.latitude;
      if (punto.longitude < oeste) oeste = punto.longitude;
      if (punto.longitude > este) este = punto.longitude;
    }

    if (sur == norte && oeste == este) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(puntos.first, 15),
      );
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(sur, oeste),
          northeast: LatLng(norte, este),
        ),
        65,
      ),
    );
  }

  Future<void> _agregar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarNegocioWeb(
          usuario: widget.usuario,
        ),
      ),
    );

    if (mounted) {
      await _cargarNegocios();
    }
  }

  void _verEnMapa(Map<String, dynamic> negocio) {
    final punto = _coordenadas(negocio);

    if (punto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este negocio no tiene coordenadas válidas.',
          ),
        ),
      );
      return;
    }

    if (_mapController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El mapa todavía está cargando.'),
        ),
      );
      return;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(punto, 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_idNegocioPlan != null) {
      final detalle = MiPlanWeb(
        key: ValueKey('plan_$_idNegocioPlan'),
        idNegocio: _idNegocioPlan!,
        embedded: true,
        onBack: () {
          setState(() => _idNegocioPlan = null);
        },
      );

      if (widget.embedded) return detalle;

      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(child: detalle),
      );
    }

    if (_negocioHorarios != null) {
      final negocio = _negocioHorarios!;

      final detalle = HorariosWeb(
        key: ValueKey(
          'horarios_${negocio['id_negocio']}',
        ),
        negocio: negocio,
        embedded: true,
        onBack: () {
          setState(() => _negocioHorarios = null);
        },
      );

      if (widget.embedded) return detalle;

      return Scaffold(
        backgroundColor: _background,
        body: SafeArea(child: detalle),
      );
    }

    final contenido = LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final escritorio = ancho >= 1050;

        final categorias = <String>{
          'Todas',
          ..._negocios.map(_categoriaDe),
        }.toList();

        if (_cargando) {
          return const Center(
            child: CircularProgressIndicator(
              color: _orange,
            ),
          );
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _muted,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: _ink),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarNegocios,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1500,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                escritorio ? 28 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezado(escritorio),
                  const SizedBox(height: 20),

                  _resumen(escritorio),
                  const SizedBox(height: 20),

                  _filtros(categorias, escritorio),
                  const SizedBox(height: 20),

                  Expanded(
                    child: escritorio
                        ? Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _seccionLista(),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 5,
                                child: _mapa(),
                              ),
                            ],
                          )
                        : ListView(
                            children: [
                              SizedBox(
                                height: 350,
                                child: _mapa(),
                              ),
                              const SizedBox(height: 20),
                              _tituloLista(),
                              const SizedBox(height: 12),
                              if (_filtrados.isEmpty)
                                _sinResultados()
                              else
                                ..._filtrados.map(_tarjeta),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) return contenido;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Mis Negocios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargarNegocios,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: contenido,
    );
  }

  Widget _encabezado(bool escritorio) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis negocios',
          style: TextStyle(
            color: _ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Administra tus establecimientos, horarios y planes.',
          style: TextStyle(
            color: _muted,
            fontSize: 14,
          ),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      onPressed: _agregar,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Añadir negocio',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        foregroundColor: _navy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 19,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );

    if (!escritorio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          const SizedBox(height: 16),
          boton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),
        boton,
      ],
    );
  }

  Widget _resumen(bool escritorio) {
    final conUbicacion = _negocios
        .where((n) => _coordenadas(n) != null)
        .length;

    final tarjetas = [
      _estadistica(
        'Negocios registrados',
        '${_negocios.length}',
        Icons.storefront_rounded,
        _navy,
      ),
      _estadistica(
        'Con ubicación',
        '$conUbicacion',
        Icons.location_on_outlined,
        const Color(0xFF16876D),
      ),
      _estadistica(
        'Resultados visibles',
        '${_filtrados.length}',
        Icons.filter_alt_outlined,
        _orange,
      ),
    ];

    if (escritorio) {
      return Row(
        children: [
          for (int i = 0; i < tarjetas.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: tarjetas[i]),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tarjetas
          .map(
            (tarjeta) => SizedBox(
              width: 175,
              child: tarjeta,
            ),
          )
          .toList(),
    );
  }

  Widget _estadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 2,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros(
    List<String> categorias,
    bool escritorio,
  ) {
    final buscar = TextField(
      controller: _buscar,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, ubicación o descripción',
        hintStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _orange,
        ),
        suffixIcon: _buscar.text.isNotEmpty
            ? IconButton(
                onPressed: _buscar.clear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: _white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: _orange,
            width: 1.5,
          ),
        ),
      ),
    );

    final categoria = DropdownButtonFormField<String>(
      value: _categoria,
      isExpanded: true,
      dropdownColor: _white,
      decoration: InputDecoration(
        labelText: 'Categoría',
        labelStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(
          Icons.tune_rounded,
          color: _navy,
        ),
        filled: true,
        fillColor: _white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _line),
        ),
      ),
      items: categorias
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(
                c,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() => _categoria = value);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centrarEnNegocios();
        });
      },
    );

    if (!escritorio) {
      return Column(
        children: [
          buscar,
          const SizedBox(height: 12),
          categoria,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: buscar),
        const SizedBox(width: 14),
        Expanded(child: categoria),
      ],
    );
  }

  Widget _tituloLista() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Tus establecimientos',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${_filtrados.length} resultados',
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _seccionLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloLista(),
        const SizedBox(height: 14),
        Expanded(child: _lista()),
      ],
    );
  }

  Widget _lista() {
    if (_filtrados.isEmpty) return _sinResultados();

    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, index) {
        return _tarjeta(_filtrados[index]);
      },
    );
  }

  Widget _sinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 52,
              color: _muted,
            ),
            const SizedBox(height: 12),
            Text(
              _negocios.isEmpty
                  ? 'Todavía no tienes negocios registrados'
                  : 'No se encontraron coincidencias',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapa() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09102C54),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: _navy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa de ubicaciones',
                        style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Establecimientos registrados',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mostrar todos',
                  onPressed: _centrarEnNegocios,
                  icon: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _initialCenter,
                zoom: 12,
              ),
              style: _mapStyle,
              markers: _marcadores,
              zoomControlsEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _centrarEnNegocios();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Map<String, dynamic> negocio) {
    final nombre = '${negocio['nombre'] ?? 'Sin nombre'}';
    final descripcion = '${negocio['descripcion'] ?? ''}';
    final ubicacion =
        '${negocio['ubicacion'] ?? 'Ubicación no registrada'}';
    final tarifa = '${negocio['tarifa'] ?? ''}';
    final plan = '${negocio['plan_nombre'] ?? 'Sin plan'}';
    final id = int.tryParse('${negocio['id_negocio']}');

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07102C54),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _categoriaDe(negocio),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _etiqueta(
                plan,
                Icons.workspace_premium_outlined,
                _orange,
              ),
            ],
          ),

          if (descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 13),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: _muted,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ubicacion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (tarifa.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: _orange,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tarifa: $tarifa',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _botonAccion(
                'Ver en mapa',
                Icons.map_outlined,
                () => _verEnMapa(negocio),
              ),
              _botonAccion(
                'Horarios',
                Icons.schedule_rounded,
                () {
                  setState(() {
                    _negocioHorarios = negocio;
                  });
                },
              ),
              if (id != null)
                _botonAccion(
                  'Mi plan',
                  Icons.workspace_premium_outlined,
                  () {
                    setState(() {
                      _idNegocioPlan = id;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAccion(
    String texto,
    IconData icono,
    VoidCallback accion,
  ) {
    return OutlinedButton.icon(
      onPressed: accion,
      icon: Icon(icono, size: 16),
      label: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: _line),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _etiqueta(
    String texto,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: _navy),
          const SizedBox(width: 5),
          Text(
            texto,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
