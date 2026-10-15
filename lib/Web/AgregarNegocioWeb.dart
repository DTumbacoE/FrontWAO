import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Services/Negocio.dart';

const _navy = Color(0xFF081529);
const _panel = Color(0xFF142B50);
const _orange = Color(0xFFF5A623);
const _mapStyle = '''[{"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"all","stylers":[{"visibility":"off"}]}]''';

class AgregarNegocioWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const AgregarNegocioWeb({super.key, required this.usuario});
  @override
  State<AgregarNegocioWeb> createState() => _AgregarNegocioWebState();
}

class _Dia {
  final String nombre;
  bool activo = false;
  TimeOfDay apertura;
  TimeOfDay cierre;
  _Dia(this.nombre, this.apertura, this.cierre);
}

class _AgregarNegocioWebState extends State<AgregarNegocioWeb> {
  final _api = ApiNegocio();
  final _formInfo = GlobalKey<FormState>();
  final _formUbicacion = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _tarifa = TextEditingController();
  final _telefono = TextEditingController();
  final _sitio = TextEditingController();
  final _direccion = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _dias = <_Dia>[
    _Dia('Lunes', const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)),
    _Dia('Martes', const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)),
    _Dia('Miércoles', const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)),
    _Dia('Jueves', const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)),
    _Dia('Viernes', const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 18, minute: 0)),
    _Dia('Sábado', const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 15, minute: 0)),
    _Dia('Domingo', const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 13, minute: 0)),
  ];
  static const _tipos = <int, String>{1:'Hotel', 2:'Restaurante', 3:'Museo', 4:'Centro de Diversión', 5:'Transporte'};
  static const _planes = <int, String>{1:'Básico', 2:'Semestral', 3:'Premium'};
  static const _precios = <int, String>{1:'\$9.99', 2:'\$49.99', 3:'\$69.99'};
  int _paso = 0;
  int? _tipo;
  int? _plan;
  LatLng? _pin;
  GoogleMapController? _mapController;
  bool _guardando = false;
  bool _buscandoUbicacion = false;

  @override
  void dispose() {
    for (final c in [_nombre,_descripcion,_tarifa,_telefono,_sitio,_direccion,_lat,_lng]) { c.dispose(); }
    _mapController?.dispose();
    super.dispose();
  }

  void _mensaje(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: error ? Colors.redAccent : Colors.green,
    ));
  }

  void _marcar(LatLng p) {
    setState(() {
      _pin = p;
      _lat.text = p.latitude.toStringAsFixed(6);
      _lng.text = p.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _miUbicacion() async {
    if (_buscandoUbicacion) return;
    setState(() => _buscandoUbicacion = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activa los servicios de ubicación del dispositivo.');
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        throw Exception('Debes permitir el acceso a la ubicación en Chrome.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final destino = LatLng(p.latitude, p.longitude);
      _marcar(destino);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(destino, 16));
    } catch (e) {
      _mensaje(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  bool _validar() {
    if (_paso == 0) {
      if (_tipo == null) { _mensaje('Selecciona un tipo de negocio.'); return false; }
      return _formInfo.currentState?.validate() ?? false;
    }
    if (_paso == 1) {
      if (!(_formUbicacion.currentState?.validate() ?? false)) return false;
      if (_pin == null) { _mensaje('Marca la ubicación del negocio en el mapa.'); return false; }
    }
    if (_paso == 3 && _plan == null) { _mensaje('Selecciona un plan.'); return false; }
    return true;
  }

  Future<void> _siguiente() async {
    if (_guardando || !_validar()) return;
    if (_paso < 3) { setState(() => _paso++); return; }
    setState(() => _guardando = true);
    try {
      final horarios = _dias.where((d) => d.activo).map((d) => {
        'dia_semana': d.nombre,
        'hora_apertura': '${d.apertura.hour.toString().padLeft(2,'0')}:${d.apertura.minute.toString().padLeft(2,'0')}:00',
        'hora_cierre': '${d.cierre.hour.toString().padLeft(2,'0')}:${d.cierre.minute.toString().padLeft(2,'0')}:00',
      }).toList();
      final ok = await _api.crearNegocio(
        idTipoNegocio: _tipo!, idPlan: _plan!, nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(), ubicacion: _direccion.text.trim(),
        tarifa: _tarifa.text.trim(), latitud: _pin!.latitude, longitud: _pin!.longitude,
        telefono: _telefono.text.trim(), sitioWeb: _sitio.text.trim(), horarios: horarios,
      );
      if (!mounted) return;
      if (ok) {
        _mensaje('Negocio registrado correctamente.', error: false);
        Navigator.pop(context, true);
      } else {
        _mensaje('No se pudo registrar el negocio. Revisa la respuesta de la API.');
      }
    } catch (e) {
      _mensaje('Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _campo(TextEditingController ctrl, String etiqueta, {bool obligatorio=false, int lineas=1, TextInputType? tipo}) =>
    TextFormField(
      controller: ctrl, maxLines: lineas, keyboardType: tipo,
      style: const TextStyle(color: Colors.white),
      validator: obligatorio ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null : null,
      decoration: InputDecoration(labelText: etiqueta, labelStyle: const TextStyle(color: Colors.white70),
        filled: true, fillColor: const Color(0xFF20385D),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );

  Widget _informacion() => Form(key: _formInfo, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Datos del negocio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 20),
    _campo(_nombre, 'Nombre del negocio', obligatorio: true),
    const SizedBox(height: 18),
    DropdownButtonFormField<int>(
      value: _tipo,
      dropdownColor: _panel,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(labelText: 'Tipo de negocio', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder()),
      items: _tipos.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) => setState(() => _tipo = v),
    ),
    const SizedBox(height: 18),
    _campo(_descripcion, 'Descripción', lineas: 3),
    const SizedBox(height: 18),
    LayoutBuilder(builder: (context, c) => c.maxWidth > 650
      ? Row(children: [Expanded(child: _campo(_tarifa, 'Tarifa aproximada')), const SizedBox(width: 16), Expanded(child: _campo(_telefono, 'Teléfono', tipo: TextInputType.phone))])
      : Column(children: [_campo(_tarifa, 'Tarifa aproximada'), const SizedBox(height: 18), _campo(_telefono, 'Teléfono', tipo: TextInputType.phone)])),
    const SizedBox(height: 18),
    _campo(_sitio, 'Sitio web (opcional)', tipo: TextInputType.url),
  ]));

  Widget _ubicacion() => Form(key: _formUbicacion, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Ubicación del negocio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Haz clic en el mapa para marcar la dirección exacta del local. También puedes usar tu ubicación actual.', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 16),
    SizedBox(height: 400, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: GoogleMap(
      initialCameraPosition: CameraPosition(target: _pin ?? const LatLng(-2.19616, -79.88621), zoom: 13),
      onMapCreated: (controller) => _mapController = controller,
      onTap: _marcar,
      style: _mapStyle,
      markers: _pin == null ? <Marker>{} : {Marker(markerId: const MarkerId('local'), position: _pin!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), infoWindow: const InfoWindow(title: 'Ubicación del negocio'))},
      myLocationEnabled: false, myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
    ))),
    const SizedBox(height: 14),
    OutlinedButton.icon(onPressed: _buscandoUbicacion ? null : _miUbicacion,
      icon: const Icon(Icons.my_location), label: Text(_buscandoUbicacion ? 'Buscando ubicación...' : 'Usar mi ubicación actual')),
    const SizedBox(height: 18),
    _campo(_direccion, 'Dirección del negocio', obligatorio: true),
    const SizedBox(height: 18),
    Row(children: [
      Expanded(child: Text('Latitud: ${_lat.text.isEmpty ? 'Sin seleccionar' : _lat.text}', style: const TextStyle(color: Colors.white70))),
      const SizedBox(width: 12),
      Expanded(child: Text('Longitud: ${_lng.text.isEmpty ? 'Sin seleccionar' : _lng.text}', style: const TextStyle(color: Colors.white70))),
    ]),
  ]));

  Future<void> _elegirHora(_Dia dia, bool apertura) async {
    final hora = await showTimePicker(context: context, initialTime: apertura ? dia.apertura : dia.cierre);
    if (hora != null) setState(() { if (apertura) { dia.apertura = hora; } else { dia.cierre = hora; } });
  }

  Widget _horarios() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Horarios de atención', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Activa los días en que atiende tu negocio. Este paso es opcional.', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 16),
    ..._dias.map((d) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF20385D), borderRadius: BorderRadius.circular(12)),
      child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 8, children: [
        SizedBox(width: 160, child: SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(d.nombre, style: const TextStyle(color: Colors.white)), value: d.activo, activeColor: _orange, onChanged: (v) => setState(() => d.activo = v))),
        if (d.activo) ...[
          OutlinedButton(onPressed: () => _elegirHora(d, true), child: Text('Abre: ${d.apertura.format(context)}')),
          OutlinedButton(onPressed: () => _elegirHora(d, false), child: Text('Cierra: ${d.cierre.format(context)}')),
        ] else const Text('Cerrado', style: TextStyle(color: Colors.white54)),
      ]),
    ))),
  ]);

  Widget _planesWidget() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Selecciona un plan', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Selecciona uno de los planes disponibles para registrar el negocio.', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 20),
    LayoutBuilder(builder: (context, c) => Wrap(spacing: 16, runSpacing: 16, children: _planes.entries.map((e) {
      final activo = _plan == e.key;
      final ancho = c.maxWidth >= 750 ? (c.maxWidth - 32) / 3 : c.maxWidth >= 500 ? (c.maxWidth - 16) / 2 : c.maxWidth;
      return SizedBox(width: ancho, child: InkWell(onTap: () => setState(() => _plan = e.key), child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: activo ? _orange.withValues(alpha: .13) : const Color(0xFF20385D), borderRadius: BorderRadius.circular(16), border: Border.all(color: activo ? _orange : Colors.white24, width: activo ? 2 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(activo ? Icons.check_circle : Icons.workspace_premium_outlined, color: _orange, size: 30),
          const SizedBox(height: 16),
          Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_precios[e.key]!, style: const TextStyle(color: _orange, fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(e.key == 1 ? 'Hasta 5 imágenes · Sin promociones' : e.key == 2 ? 'Hasta 30 imágenes · 10 promociones' : 'Imágenes y promociones ilimitadas', style: const TextStyle(color: Colors.white70)),
        ]),
      )));
    }).toList())),
  ]);

  @override
  Widget build(BuildContext context) {
    const pasos = ['Información', 'Ubicación', 'Horarios', 'Plan'];
    return Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _orange, surface: _panel)), child: Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(backgroundColor: _navy, title: const Text('WAO · Añadir negocio'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120), child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 20, 18, 14), child: LayoutBuilder(builder: (context, c) => c.maxWidth < 540
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Paso ${_paso + 1} de 4 · ${pasos[_paso]}', style: const TextStyle(color: _orange, fontWeight: FontWeight.bold)), const SizedBox(height: 10), LinearProgressIndicator(value: (_paso + 1) / 4, color: _orange)])
          : Row(children: List.generate(4, (i) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: i == _paso ? _orange.withValues(alpha: .18) : _panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: i == _paso ? _orange : Colors.white12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i < _paso ? Icons.check_circle : Icons.circle_outlined, color: i <= _paso ? _orange : Colors.white54, size: 17), const SizedBox(width: 7), Flexible(child: Text(pasos[i], overflow: TextOverflow.ellipsis, style: TextStyle(color: i == _paso ? _orange : Colors.white70)))]),
          ))))))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 24), child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20)), child: switch (_paso) {0 => _informacion(), 1 => _ubicacion(), 2 => _horarios(), _ => _planesWidget()}))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 22), child: Row(children: [
          if (_paso > 0) OutlinedButton.icon(onPressed: _guardando ? null : () => setState(() => _paso--), icon: const Icon(Icons.arrow_back), label: const Text('Atrás')),
          const Spacer(),
          FilledButton.icon(onPressed: _guardando ? null : _siguiente, icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_paso == 3 ? Icons.save : Icons.arrow_forward), label: Text(_guardando ? 'Guardando...' : _paso == 3 ? 'Registrar negocio' : 'Siguiente')),
        ])),
      ]))),
    ));
  }
}
