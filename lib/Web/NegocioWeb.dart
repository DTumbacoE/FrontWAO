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
const Color _panel = Colors.white;
const Color _panelLight = Color(0xFFEAF1FA);
const Color _orange = Color(0xFFF5A623);
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
  const NegociosWeb({super.key, required this.usuario, this.embedded = false});
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
    if (mounted) setState(() {});
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnNegocios());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los negocios. Inténtalo de nuevo.';
      });
    }
  }
  LatLng? _coordenadas(Map<String, dynamic> negocio) {
    final lat = double.tryParse('${negocio['latitud'] ?? ''}');
    final lng = double.tryParse('${negocio['longitud'] ?? ''}');
    if (lat == null || lng == null || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
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
      final coincideCategoria = _categoria == 'Todas' || _categoriaDe(negocio) == _categoria;
      final contenido = '${negocio['nombre'] ?? ''} ${negocio['ubicacion'] ?? ''} ${negocio['descripcion'] ?? ''}'.toLowerCase();
      return coincideCategoria && contenido.contains(texto);
    }).toList();
  }
  Set<Marker> get _marcadores {
    final resultado = <Marker>{};
    for (final negocio in _filtrados) {
      final punto = _coordenadas(negocio);
      if (punto == null) continue;
      resultado.add(Marker(
        markerId: MarkerId('negocio_${negocio['id_negocio']}'),
        position: punto,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '${negocio['nombre'] ?? 'Negocio'}',
          snippet: '${negocio['ubicacion'] ?? ''}',
        ),
      ));
    }
    return resultado;
  }
  void _centrarEnNegocios() {
    if (!mounted || _mapController == null) return;
    final puntos = _marcadores.map((m) => m.position).toList();
    if (puntos.isEmpty) return;
    if (puntos.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(puntos.first, 15));
      return;
    }
    double sur = puntos.first.latitude;
    double norte = sur;
    double oeste = puntos.first.longitude;
    double este = oeste;
    for (final p in puntos) {
      if (p.latitude < sur) sur = p.latitude;
      if (p.latitude > norte) norte = p.latitude;
      if (p.longitude < oeste) oeste = p.longitude;
      if (p.longitude > este) este = p.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(sur, oeste), northeast: LatLng(norte, este)),
      55,
    ));
  }
  Future<void> _agregar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AgregarNegocioWeb(usuario: widget.usuario)),
    );
    if (mounted) await _cargarNegocios();
  }
  void _verEnMapa(Map<String, dynamic> negocio) {
    final punto = _coordenadas(negocio);
    if (punto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este negocio no tiene coordenadas válidas.')),
      );
      return;
    }
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(punto, 16));
  }
  @override
  Widget build(BuildContext context) {
    if (_idNegocioPlan != null) {
      final detalle = MiPlanWeb(
        key: ValueKey('plan_$_idNegocioPlan'),
        idNegocio: _idNegocioPlan!,
        embedded: true,
        onBack: () => setState(() => _idNegocioPlan = null),
      );
      if (widget.embedded) return detalle;
      return Scaffold(backgroundColor: _background, body: SafeArea(child: detalle));
    }
    if (_negocioHorarios != null) {
      final negocio = _negocioHorarios!;
      final detalle = HorariosWeb(
        key: ValueKey('horarios_${negocio['id_negocio']}'),
        negocio: negocio,
        embedded: true,
        onBack: () => setState(() => _negocioHorarios = null),
      );
      if (widget.embedded) return detalle;
      return Scaffold(backgroundColor: _background, body: SafeArea(child: detalle));
    }
    final ancho = MediaQuery.sizeOf(context).width;
    final escritorio = ancho >= 1050;
    final categorias = <String>{'Todas', ..._negocios.map(_categoriaDe)}.toList();
    final content = _cargando
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: _ink)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _cargarNegocios, child: const Text('Reintentar')),
                ]))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1500),
                    child: Padding(
                      padding: EdgeInsets.all(escritorio ? 24 : 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _encabezado(escritorio),
                        const SizedBox(height: 16),
                        _filtros(categorias, escritorio),
                        const SizedBox(height: 16),
                        Expanded(
                          child: escritorio
                              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  Expanded(flex: 6, child: _lista()),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 5, child: _mapa()),
                                ])
                              : ListView(children: [
                                  SizedBox(height: 320, child: _mapa()),
                                  const SizedBox(height: 18),
                                  ..._filtrados.map(_tarjeta),
                                  if (_filtrados.isEmpty) _sinResultados(),
                                ]),
                        ),
                      ]),
                    ),
                  ),
                );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Mis Negocios', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Actualizar', onPressed: _cargando ? null : _cargarNegocios, icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 12),
        ],
      ),
      body: content,
    );
  }
  Widget _encabezado(bool escritorio) {
    final titulo = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Administra tus establecimientos',
          style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text('${_negocios.length} negocio(s) registrado(s)', style: const TextStyle(color: _muted)),
    ]);
    final boton = ElevatedButton.icon(
      onPressed: _agregar,
      style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: _navy,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18)),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Añadir Negocio', style: TextStyle(fontWeight: FontWeight.bold)),
    );
    return escritorio
        ? Row(children: [Expanded(child: titulo), boton])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [titulo, const SizedBox(height: 14), boton]);
  }
  Widget _filtros(List<String> categorias, bool escritorio) {
    final buscar = TextField(
      controller: _buscar,
      style: const TextStyle(color: _ink),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, ubicación o descripción',
        hintStyle: const TextStyle(color: _muted),
        prefixIcon: const Icon(Icons.search, color: _orange),
        filled: true, fillColor: _panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
      ),
    );
    final categoria = DropdownButtonFormField<String>(
      value: _categoria,
      dropdownColor: _panel,
      style: const TextStyle(color: _ink),
      decoration: InputDecoration(
        labelText: 'Categoría', labelStyle: const TextStyle(color: _muted),
        filled: true, fillColor: _panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
      ),
      items: categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _categoria = value);
        WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnNegocios());
      },
    );
    if (!escritorio) return Column(children: [buscar, const SizedBox(height: 12), categoria]);
    return Row(children: [Expanded(flex: 3, child: buscar), const SizedBox(width: 14), Expanded(child: categoria)]);
  }
  Widget _lista() {
    if (_filtrados.isEmpty) return _sinResultados();
    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, index) => _tarjeta(_filtrados[index]),
    );
  }
  Widget _sinResultados() => Center(child: Padding(
    padding: const EdgeInsets.all(36),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.storefront_outlined, size: 60, color: _muted),
      const SizedBox(height: 12),
      Text(_negocios.isEmpty ? 'Todavía no tienes negocios registrados' : 'No se encontraron coincidencias',
          textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 16)),
    ]),
  ));
  Widget _mapa() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _line), boxShadow: const [BoxShadow(color: Color(0x0A102C54), blurRadius: 18, offset: Offset(0, 6))]),
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.map_outlined, color: _navy),
          const SizedBox(width: 10),
          const Expanded(child: Text('Ubicación de mis negocios',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(tooltip: 'Ver todos los negocios', onPressed: _centrarEnNegocios,
              icon: const Icon(Icons.center_focus_strong, color: _navy)),
        ]),
      ),
      Expanded(child: GoogleMap(
        initialCameraPosition: const CameraPosition(target: _initialCenter, zoom: 12),
        style: _mapStyle,
        markers: _marcadores,
        zoomControlsEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) => _centrarEnNegocios());
        },
      )),
    ]),
  );
  Widget _tarjeta(Map<String, dynamic> negocio) {
    final nombre = '${negocio['nombre'] ?? 'Sin nombre'}';
    final descripcion = '${negocio['descripcion'] ?? ''}';
    final ubicacion = '${negocio['ubicacion'] ?? 'Ubicación no registrada'}';
    final tarifa = '${negocio['tarifa'] ?? ''}';
    final plan = '${negocio['plan_nombre'] ?? 'Sin plan'}';
    final id = int.tryParse('${negocio['id_negocio']}');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line), boxShadow: const [BoxShadow(color: Color(0x0A102C54), blurRadius: 14, offset: Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _etiqueta(_categoriaDe(negocio), Icons.storefront_rounded, _orange),
          _etiqueta(plan, Icons.workspace_premium_outlined, Colors.amber),
        ]),
        const SizedBox(height: 12),
        Text(nombre, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.bold)),
        if (descripcion.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.location_on_outlined, color: _muted, size: 17),
          const SizedBox(width: 5),
          Expanded(child: Text(ubicacion, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted))),
        ]),
        if (tarifa.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Tarifa: $tarifa', style: const TextStyle(color: _orange, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        const Divider(color: _line),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _line)), onPressed: () => _verEnMapa(negocio),
              icon: const Icon(Icons.map_outlined, size: 17), label: const Text('Ver en mapa')),
          OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _line)), onPressed: () => setState(() => _negocioHorarios = negocio),
              icon: const Icon(Icons.schedule, size: 17), label: const Text('Horarios')),
          if (id != null) OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: _navy, side: const BorderSide(color: _line)), onPressed: () => setState(() => _idNegocioPlan = id),
              icon: const Icon(Icons.workspace_premium_outlined, size: 17), label: const Text('Mi plan')),
        ]),
      ]),
    );
  }
  Widget _etiqueta(String texto, IconData icono, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icono, size: 15, color: color),
      const SizedBox(width: 6),
      Text(texto, style: TextStyle(color: color == _orange ? _navy : color, fontSize: 12, fontWeight: FontWeight.bold)),
    ]),
  );
}
