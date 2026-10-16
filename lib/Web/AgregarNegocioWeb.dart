
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Services/Negocio.dart';

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

class AgregarNegocioWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const AgregarNegocioWeb({
    super.key,
    required this.usuario,
  });

  @override
  State<AgregarNegocioWeb> createState() => _AgregarNegocioWebState();
}

class _Dia {
  final String nombre;
  bool activo;
  TimeOfDay apertura;
  TimeOfDay cierre;

  _Dia(
    this.nombre,
    this.apertura,
    this.cierre, {
    this.activo = false,
  });
}

class _AgregarNegocioWebState extends State<AgregarNegocioWeb> {
  final ApiNegocio _api = ApiNegocio();

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
    _Dia(
      'Lunes',
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ),
    _Dia(
      'Martes',
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ),
    _Dia(
      'Miércoles',
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ),
    _Dia(
      'Jueves',
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ),
    _Dia(
      'Viernes',
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ),
    _Dia(
      'Sábado',
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
    ),
    _Dia(
      'Domingo',
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
    ),
  ];

  static const _tipos = <int, String>{
    1: 'Hotel',
    2: 'Restaurante',
    3: 'Museo',
    4: 'Centro de Diversión',
    5: 'Transporte',
  };

  static const _planes = <int, String>{
    1: 'Básico',
    2: 'Semestral',
    3: 'Premium',
  };

  static const _precios = <int, String>{
    1: '\$9.99',
    2: '\$49.99',
    3: '\$69.99',
  };

  static const _pasos = [
    'Información',
    'Ubicación',
    'Horarios',
    'Plan',
  ];

  static const _iconosPasos = [
    Icons.storefront_outlined,
    Icons.location_on_outlined,
    Icons.schedule_outlined,
    Icons.workspace_premium_outlined,
  ];

  int _paso = 0;
  int? _tipo;
  int? _plan;

  LatLng? _pin;
  GoogleMapController? _mapController;

  bool _guardando = false;
  bool _buscandoUbicacion = false;

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _descripcion,
      _tarifa,
      _telefono,
      _sitio,
      _direccion,
      _lat,
      _lng,
    ]) {
      controller.dispose();
    }

    _mapController?.dispose();
    super.dispose();
  }

  void _mensaje(String mensaje, {bool error = true}) {
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

  void _marcar(LatLng punto) {
    setState(() {
      _pin = punto;
      _lat.text = punto.latitude.toStringAsFixed(6);
      _lng.text = punto.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _miUbicacion() async {
    if (_buscandoUbicacion) return;

    setState(() => _buscandoUbicacion = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Activa los servicios de ubicación del dispositivo.',
        );
      }

      var permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        throw Exception(
          'Debes permitir el acceso a la ubicación en el navegador.',
        );
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      final destino = LatLng(
        posicion.latitude,
        posicion.longitude,
      );

      _marcar(destino);

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(destino, 16),
      );
    } catch (e) {
      _mensaje(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _buscandoUbicacion = false);
      }
    }
  }

  int _minutos(TimeOfDay hora) {
    return hora.hour * 60 + hora.minute;
  }

  bool _validar() {
    if (_paso == 0) {
      if (_tipo == null) {
        _mensaje('Selecciona un tipo de negocio.');
        return false;
      }

      return _formInfo.currentState?.validate() ?? false;
    }

    if (_paso == 1) {
      if (!(_formUbicacion.currentState?.validate() ?? false)) {
        return false;
      }

      if (_pin == null) {
        _mensaje('Selecciona la ubicación del negocio en el mapa.');
        return false;
      }
    }

    if (_paso == 2) {
      for (final dia in _dias.where((d) => d.activo)) {
        if (_minutos(dia.cierre) <= _minutos(dia.apertura)) {
          _mensaje(
            'En ${dia.nombre}, la hora de cierre debe ser posterior a la apertura.',
          );
          return false;
        }
      }
    }

    if (_paso == 3 && _plan == null) {
      _mensaje('Selecciona un plan.');
      return false;
    }

    return true;
  }

  Future<void> _siguiente() async {
    if (_guardando || !_validar()) return;

    if (_paso < 3) {
      setState(() => _paso++);
      return;
    }

    setState(() => _guardando = true);

    try {
      final horarios = _dias
          .where((dia) => dia.activo)
          .map(
            (dia) => {
              'dia_semana': dia.nombre,
              'hora_apertura':
                  '${dia.apertura.hour.toString().padLeft(2, '0')}:'
                  '${dia.apertura.minute.toString().padLeft(2, '0')}:00',
              'hora_cierre':
                  '${dia.cierre.hour.toString().padLeft(2, '0')}:'
                  '${dia.cierre.minute.toString().padLeft(2, '0')}:00',
            },
          )
          .toList();

      final ok = await _api.crearNegocio(
        idTipoNegocio: _tipo!,
        idPlan: _plan!,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        ubicacion: _direccion.text.trim(),
        tarifa: _tarifa.text.trim(),
        latitud: _pin!.latitude,
        longitud: _pin!.longitude,
        telefono: _telefono.text.trim(),
        sitioWeb: _sitio.text.trim(),
        horarios: horarios,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      } else {
        _mensaje(
          'No se pudo registrar el negocio. Revisa la respuesta de la API.',
        );
      }
    } catch (e) {
      _mensaje('Error al registrar el negocio: $e');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  InputDecoration _decoracion(
    String etiqueta, {
    IconData? icono,
    String? ayuda,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: ayuda,
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: _muted),
      prefixIcon: icono == null
          ? null
          : Icon(icono, color: _muted, size: 20),
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
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool obligatorio = false,
    int lineas = 1,
    TextInputType? tipo,
    IconData? icono,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: lineas,
      keyboardType: tipo,
      style: const TextStyle(color: _ink),
      validator: obligatorio
          ? (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            }
          : null,
      decoration: _decoracion(
        etiqueta,
        icono: icono,
      ),
    );
  }

  Widget _tituloSeccion(
    String titulo,
    String descripcion,
    IconData icono,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E3),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icono,
                color: _orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          descripcion,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _informacion() {
    return Form(
      key: _formInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            'Información del negocio',
            'Completa los datos principales de tu establecimiento.',
            Icons.storefront_rounded,
          ),

          _campo(
            _nombre,
            'Nombre del negocio',
            obligatorio: true,
            icono: Icons.store_outlined,
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<int>(
            value: _tipo,
            isExpanded: true,
            dropdownColor: _white,
            style: const TextStyle(color: _ink),
            decoration: _decoracion(
              'Tipo de negocio',
              icono: Icons.category_outlined,
            ),
            items: _tipos.entries
                .map(
                  (tipo) => DropdownMenuItem(
                    value: tipo.key,
                    child: Text(tipo.value),
                  ),
                )
                .toList(),
            onChanged: (valor) {
              setState(() => _tipo = valor);
            },
          ),

          const SizedBox(height: 18),

          _campo(
            _descripcion,
            'Descripción del establecimiento',
            lineas: 4,
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 650) {
                return Row(
                  children: [
                    Expanded(
                      child: _campo(
                        _tarifa,
                        'Tarifa aproximada',
                        icono: Icons.payments_outlined,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _campo(
                        _telefono,
                        'Teléfono',
                        tipo: TextInputType.phone,
                        icono: Icons.phone_outlined,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _campo(
                    _tarifa,
                    'Tarifa aproximada',
                    icono: Icons.payments_outlined,
                  ),
                  const SizedBox(height: 18),
                  _campo(
                    _telefono,
                    'Teléfono',
                    tipo: TextInputType.phone,
                    icono: Icons.phone_outlined,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          _campo(
            _sitio,
            'Sitio web (opcional)',
            tipo: TextInputType.url,
            icono: Icons.language_rounded,
          ),
        ],
      ),
    );
  }

  Widget _ubicacion() {
    return Form(
      key: _formUbicacion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            'Ubicación del establecimiento',
            'Marca en el mapa la ubicación exacta de tu negocio.',
            Icons.location_on_outlined,
          ),

          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        color: _navy,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Selecciona un punto en el mapa',
                          style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 380,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _pin ?? _initialCenter,
                      zoom: 13,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: _marcar,
                    style: _mapStyle,
                    markers: _pin == null
                        ? <Marker>{}
                        : {
                            Marker(
                              markerId: const MarkerId('local'),
                              position: _pin!,
                              icon: BitmapDescriptor
                                  .defaultMarkerWithHue(
                                BitmapDescriptor.hueOrange,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Ubicación del negocio',
                              ),
                            ),
                          },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed:
                _buscandoUbicacion ? null : _miUbicacion,
            icon: _buscandoUbicacion
                ? const SizedBox(
                    height: 17,
                    width: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _buscandoUbicacion
                  ? 'Buscando ubicación...'
                  : 'Usar mi ubicación actual',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: _line),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 22),

          _campo(
            _direccion,
            'Dirección del negocio',
            obligatorio: true,
            icono: Icons.place_outlined,
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 25,
              runSpacing: 12,
              children: [
                _datoCoordenada(
                  'Latitud',
                  _lat.text.isEmpty
                      ? 'Sin seleccionar'
                      : _lat.text,
                ),
                _datoCoordenada(
                  'Longitud',
                  _lng.text.isEmpty
                      ? 'Sin seleccionar'
                      : _lng.text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoCoordenada(
    String titulo,
    String valor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _elegirHora(
    _Dia dia,
    bool apertura,
  ) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: apertura ? dia.apertura : dia.cierre,
    );

    if (hora == null || !mounted) return;

    setState(() {
      if (apertura) {
        dia.apertura = hora;
      } else {
        dia.cierre = hora;
      }
    });
  }

  Widget _horarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion(
          'Horarios de atención',
          'Activa los días en que tu establecimiento estará abierto. Este paso es opcional.',
          Icons.schedule_rounded,
        ),

        ..._dias.map((dia) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dia.activo ? _orange : _line,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compacto = constraints.maxWidth < 560;

                final selector = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: dia.activo,
                      activeColor: _orange,
                      onChanged: (valor) {
                        setState(() => dia.activo = valor);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dia.nombre,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );

                final horas = dia.activo
                    ? Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _botonHora(
                            'Apertura',
                            dia.apertura,
                            () => _elegirHora(dia, true),
                          ),
                          _botonHora(
                            'Cierre',
                            dia.cierre,
                            () => _elegirHora(dia, false),
                          ),
                        ],
                      )
                    : const Text(
                        'Cerrado',
                        style: TextStyle(color: _muted),
                      );

                if (compacto) {
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      selector,
                      const SizedBox(height: 10),
                      horas,
                    ],
                  );
                }

                return Row(
                  children: [
                    SizedBox(width: 200, child: selector),
                    Expanded(child: horas),
                  ],
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _botonHora(
    String etiqueta,
    TimeOfDay hora,
    VoidCallback accion,
  ) {
    return OutlinedButton.icon(
      onPressed: accion,
      icon: const Icon(
        Icons.access_time_rounded,
        size: 17,
      ),
      label: Text(
        '$etiqueta: ${hora.format(context)}',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: _line),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _planesWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tituloSeccion(
          'Selecciona tu plan',
          'Elige el plan que deseas asociar al establecimiento.',
          Icons.workspace_premium_outlined,
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;

            final columnas = ancho >= 750
                ? 3
                : ancho >= 500
                    ? 2
                    : 1;

            final espacio = 14.0;

            final anchoTarjeta =
                (ancho - espacio * (columnas - 1)) /
                    columnas;

            return Wrap(
              spacing: espacio,
              runSpacing: espacio,
              children: _planes.entries.map((plan) {
                final seleccionado = _plan == plan.key;

                return SizedBox(
                  width: anchoTarjeta,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => _plan = plan.key);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? const Color(0xFFFFF8EC)
                            : _white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: seleccionado
                              ? _orange
                              : _line,
                          width: seleccionado ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                seleccionado
                                    ? Icons.check_circle_rounded
                                    : Icons.workspace_premium_outlined,
                                color: seleccionado
                                    ? _orange
                                    : _muted,
                                size: 28,
                              ),
                              const Spacer(),
                              if (seleccionado)
                                const Text(
                                  'Seleccionado',
                                  style: TextStyle(
                                    color: _orange,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Text(
                            plan.value,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            _precios[plan.key]!,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            plan.key == 1
                                ? 'Hasta 5 imágenes · Sin promociones'
                                : plan.key == 2
                                    ? 'Hasta 30 imágenes · 10 promociones'
                                    : 'Imágenes y promociones ilimitadas',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _indicadorPasos(bool compacto) {
    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso ${_paso + 1} de 4 · ${_pasos[_paso]}',
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_paso + 1) / 4,
              minHeight: 7,
              color: _orange,
              backgroundColor: _line,
            ),
          ),
        ],
      );
    }

    return Row(
      children: List.generate(4, (index) {
        final activo = index == _paso;
        final completado = index < _paso;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: activo
                  ? const Color(0xFFFFF4E3)
                  : _white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: activo ? _orange : _line,
                width: activo ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  completado
                      ? Icons.check_circle_rounded
                      : _iconosPasos[index],
                  color: activo || completado
                      ? _orange
                      : _muted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _pasos[index],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activo ? _navy : _muted,
                      fontWeight: activo
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _contenidoPaso() {
    switch (_paso) {
      case 0:
        return _informacion();
      case 1:
        return _ubicacion();
      case 2:
        return _horarios();
      default:
        return _planesWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: _orange,
          surface: _white,
          onSurface: _ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _white,
          foregroundColor: _navy,
          elevation: 0,
          surfaceTintColor: _white,
          title: const Text(
            'Registrar negocio',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _guardando
                ? null
                : () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1120,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compacto = constraints.maxWidth < 600;

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compacto ? 16 : 24,
                        22,
                        compacto ? 16 : 24,
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Añadir establecimiento',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Completa los pasos para registrar tu negocio en WAO.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _indicadorPasos(compacto),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compacto ? 16 : 24,
                          8,
                          compacto ? 16 : 24,
                          24,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            compacto ? 18 : 28,
                          ),
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius:
                                BorderRadius.circular(19),
                            border: Border.all(color: _line),
                          ),
                          child: _contenidoPaso(),
                        ),
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compacto ? 16 : 24,
                        vertical: 15,
                      ),
                      decoration: const BoxDecoration(
                        color: _white,
                        border: Border(
                          top: BorderSide(color: _line),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_paso > 0)
                            OutlinedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : () {
                                      setState(() => _paso--);
                                    },
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                              ),
                              label: const Text('Anterior'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _navy,
                                side: const BorderSide(
                                  color: _line,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 19,
                                  vertical: 17,
                                ),
                              ),
                            ),

                          const Spacer(),

                          FilledButton.icon(
                            onPressed:
                                _guardando ? null : _siguiente,
                            icon: _guardando
                                ? const SizedBox(
                                    height: 17,
                                    width: 17,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _paso == 3
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                            label: Text(
                              _guardando
                                  ? 'Guardando...'
                                  : _paso == 3
                                      ? 'Registrar negocio'
                                      : 'Continuar',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: _navy,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 23,
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
