import 'package:flutter/material.dart';
import '../Services/Usuarios.dart';
import 'ConfiguracionCuentaWeb.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../Services/Negocio.dart';
import 'NegocioWeb.dart';
import 'ImagenesWeb.dart';
import 'MiPlanWeb.dart';

const _bg = Color(0xFFF5F8FC);
const _side = Color(0xFF102C54);
const _panel = Colors.white;
const _ink = Color(0xFF102C54);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE0E8F2);
const _orange = Color(0xFFF5A623);
const _mapCenter = LatLng(
  -2.2267,
  -80.8587,
); // Vista inicial mientras se obtienen datos.
const double _radioKm = 20.0;
const String _waoMapStyle = r'''[
  {"featureType":"poi","elementType":"all","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","elementType":"all","stylers":[{"visibility":"off"}]}
]''';

class HomeWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onLogout;
  const HomeWeb({super.key, required this.usuario, required this.onLogout});
  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _NavEntry {
  final String title;
  final IconData icon;
  const _NavEntry(this.title, this.icon);
}

class _HomeWebState extends State<HomeWeb> {
  String _selected = 'Inicio';
  late Map<String, dynamic> _usuarioActual;
  final ApiUsuario _apiUsuario = ApiUsuario();
  final ApiNegocio _apiNegocio = ApiNegocio();
  Set<Marker> _markers = {};
  LatLng? _posicionUsuario;
  bool _cargandoMapa = false;
  String? _mensajeMapa;
  GoogleMapController? _mapController;
  @override
  void initState() {
    super.initState();
    _usuarioActual = Map<String, dynamic>.from(widget.usuario);
    _refrescarPerfil();
    if (_role == 2 || _role == 3) _cargarMapa();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _refrescarPerfil() async {
    final datos = await _apiUsuario.obtenerPerfil();
    if (datos != null && mounted) {
      setState(() => _usuarioActual.addAll(datos));
    }
  }

  void _actualizarUsuario(Map<String, dynamic> cambios) {
    if (mounted) setState(() => _usuarioActual.addAll(cambios));
  }

  Widget _avatar(double radius, {bool oscuro = false}) {
    final foto = _usuarioActual['foto_perfil_url']?.toString() ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: oscuro ? _side : _orange,
      backgroundImage: foto.startsWith('https://') ? NetworkImage(foto) : null,
      child: foto.startsWith('https://')
          ? null
          : Text(
              _name[0].toUpperCase(),
              style: TextStyle(
                color: oscuro ? _orange : _side,
                fontWeight: FontWeight.w800,
                fontSize: radius * .85,
              ),
            ),
    );
  }

  Future<void> _cargarMapa() async {
    if (_cargandoMapa) return;
    setState(() {
      _cargandoMapa = true;
      _mensajeMapa = null;
    });
    try {
      LatLng? ubicacion;
      if (_role == 3) {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception(
            'Activa los servicios de ubicación para buscar negocios.',
          );
        }
        var permiso = await Geolocator.checkPermission();
        if (permiso == LocationPermission.denied) {
          permiso = await Geolocator.requestPermission();
        }
        if (permiso == LocationPermission.denied ||
            permiso == LocationPermission.deniedForever) {
          throw Exception(
            'Permite el acceso a tu ubicación en el navegador para ver negocios cercanos.',
          );
        }
        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        ubicacion = LatLng(posicion.latitude, posicion.longitude);
      }
      final data = _role == 2
          ? await _apiNegocio.misNegocios()
          : await _apiNegocio.obtenerTodos();
      final Set<Marker> marcadores = {};
      for (final item in data) {
        if (item is! Map) continue;
        final negocio = Map<String, dynamic>.from(item);
        final lat = double.tryParse('${negocio['latitud'] ?? ''}');
        final lng = double.tryParse('${negocio['longitud'] ?? ''}');
        if (lat == null ||
            lng == null ||
            !lat.isFinite ||
            !lng.isFinite ||
            lat < -90 ||
            lat > 90 ||
            lng < -180 ||
            lng > 180)
          continue;
        if (_role == 3) {
          // Solo negocios activos. El backend debe aplicar además sus reglas de publicación.
          if ('${negocio['estado'] ?? 1}' == '0' ||
              '${negocio['estado']}'.toLowerCase() == 'false')
            continue;
          final metros = Geolocator.distanceBetween(
            ubicacion!.latitude,
            ubicacion.longitude,
            lat,
            lng,
          );
          if (metros > _radioKm * 1000) continue;
        }
        marcadores.add(
          Marker(
            markerId: MarkerId('wao_${negocio['id_negocio']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '${negocio['nombre'] ?? 'Negocio WAO'}',
              snippet: '${negocio['ubicacion'] ?? ''}',
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _posicionUsuario = ubicacion;
        _markers = marcadores;
        _cargandoMapa = false;
        _mensajeMapa = marcadores.isEmpty
            ? (_role == 3
                  ? 'No hay negocios registrados cerca de tu ubicación.'
                  : 'No tienes negocios con coordenadas disponibles.')
            : '${marcadores.length} negocio(s) en el mapa';
      });
      if (ubicacion != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(ubicacion, 14),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoMapa = false;
        _markers = {};
        _mensajeMapa = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _role => int.tryParse('${_usuarioActual['id_rol'] ?? 3}') ?? 3;
  String get _roleName => switch (_role) {
    1 => 'Administrador',
    2 => 'Propietario',
    _ => 'Turista',
  };
  String get _name {
    final n =
        '${_usuarioActual['nombre'] ?? ''} ${_usuarioActual['apellido'] ?? ''}'
            .trim();
    return n.isEmpty ? 'Usuario WAO' : n;
  }

  List<_NavEntry> get _menu => [
    const _NavEntry('Inicio', Icons.dashboard_outlined),
    if (_role == 1) ...[
      const _NavEntry('Usuarios', Icons.people_outline),
      const _NavEntry('Negocios', Icons.store_outlined),
      const _NavEntry('Categorías', Icons.category_outlined),
      const _NavEntry('Reportes', Icons.bar_chart_outlined),
    ] else if (_role == 2) ...[
      const _NavEntry('Mapa', Icons.map_outlined),
      const _NavEntry('Mis Negocios', Icons.store_outlined),
      const _NavEntry('Reservas', Icons.event_note_outlined),
      const _NavEntry('Galería', Icons.photo_library_outlined),
      const _NavEntry('Opiniones', Icons.rate_review_outlined),
      const _NavEntry('Reportes', Icons.bar_chart_outlined),
    ] else ...[
      const _NavEntry('Mapa', Icons.map_outlined),
      const _NavEntry('Explorar negocios', Icons.travel_explore_outlined),
      const _NavEntry('Mis reservas', Icons.event_note_outlined),
      const _NavEntry('Favoritos', Icons.favorite_outline),
      const _NavEntry('Reseñas', Icons.rate_review_outlined),
    ],
    const _NavEntry('Mi perfil', Icons.person_outline),
  ];
  void _choose(String label) {
    setState(() => _selected = label);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta de WAO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiUsuario.logout();

      if (!mounted) return;

      widget.onLogout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión. Inténtalo nuevamente.'),
        ),
      );
    }
  }

  Widget _navButton(_NavEntry item) {
    final active = _selected == item.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton(
        onPressed: () => _choose(item.title),
        style: TextButton.styleFrom(
          foregroundColor: active ? _orange : Colors.white,
          backgroundColor: active
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 18),
            const SizedBox(width: 7),
            Text(
              item.title,
              style: TextStyle(
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _accountOption(
    String value,
    String title,
    IconData icon, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFBF3547) : _ink;
    return PopupMenuItem<String>(
      value: value,
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!danger)
            const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
        ],
      ),
    );
  }

  Widget _topBar(bool desktop) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: _side,
        boxShadow: [
          BoxShadow(
            color: Color(0x200B2444),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          InkWell(
            onTap: () => _choose('Inicio'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Image.asset(
                'icon/Logo2.png',
                width: desktop ? 115 : 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'WAO',
                    style: TextStyle(
                      color: _orange,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 20),

          if (desktop)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _menu
                      .where((e) => e.title != 'Mi perfil')
                      .map(_navButton)
                      .toList(),
                ),
              ),
            )
          else ...[
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: 'Abrir navegación',
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onSelected: _choose,
              itemBuilder: (_) => _menu
                  .map(
                    (item) => PopupMenuItem<String>(
                      value: item.title,
                      child: Row(
                        children: [
                          Icon(item.icon, size: 19, color: _side),
                          const SizedBox(width: 10),
                          Text(item.title),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (desktop) const SizedBox(width: 14),
          PopupMenuButton<String>(
            tooltip: 'Opciones de mi cuenta',
            offset: const Offset(0, 16),
            elevation: 14,
            color: Colors.white,
            surfaceTintColor: Colors.white,
            constraints: const BoxConstraints(minWidth: 290, maxWidth: 330),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: _border),
            ),
            onSelected: (value) {
              switch (value) {
                case 'perfil':
                  _choose('Mi perfil');
                  break;
                case 'configuracion':
                  _choose('Configuración de cuenta');
                  break;
                case 'banco':
                  _choose('Cuenta bancaria');
                  break;
                case 'planes':
                  _choose('Mis planes');
                  break;
                case 'salir':
                  _logout();
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                height: 92,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _avatar(24, oscuro: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${_usuarioActual['correo'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _roleName,
                            style: const TextStyle(
                              color: Color(0xFF2463A5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 10),
              _accountOption(
                'perfil',
                'Mi perfil',
                Icons.person_outline_rounded,
              ),
              _accountOption(
                'configuracion',
                'Configuración de cuenta',
                Icons.settings_outlined,
              ),
              if (_role == 2) ...[
                _accountOption(
                  'banco',
                  'Cuenta bancaria',
                  Icons.account_balance_outlined,
                ),
                _accountOption(
                  'planes',
                  'Mis planes',
                  Icons.workspace_premium_outlined,
                ),
              ],
              const PopupMenuDivider(height: 10),
              _accountOption(
                'salir',
                'Cerrar sesión',
                Icons.logout_rounded,
                danger: true,
              ),
              const PopupMenuItem<String>(
                enabled: false,
                height: 5,
                child: SizedBox.shrink(),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(19),
                if (desktop) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 135),
                    child: Text(
                      _name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(_NavEntry item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _choose(item.title),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x100D2247),
              blurRadius: 16,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: _side, size: 26),
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Abrir sección',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapSection() {
    final propietario = _role == 2;
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D2247),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_outlined, color: _side),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  propietario ? 'Mapa de mis negocios' : 'Negocios cercanos',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualizar negocios',
                onPressed: _cargandoMapa ? null : _cargarMapa,
                icon: const Icon(Icons.refresh, color: _side),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            propietario
                ? 'Se muestran tus establecimientos registrados con coordenadas.'
                : 'Solo establecimientos registrados en WAO dentro de tu ubicación.',
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          if (_cargandoMapa)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(color: _orange),
            ),
          if (_mensajeMapa != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_mensajeMapa!, style: const TextStyle(color: _muted)),
            ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 380,
              width: double.infinity,
              child: GoogleMap(
                key: const ValueKey('wao-mapa-seccion'),
                initialCameraPosition: CameraPosition(
                  target:
                      _posicionUsuario ??
                      (_markers.isNotEmpty
                          ? _markers.first.position
                          : _mapCenter),
                  zoom: 12,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;

                  if (_posicionUsuario != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_posicionUsuario!, 14),
                    );
                  }
                },
                mapType: MapType.normal,
                style: _waoMapStyle,
                zoomControlsEnabled: true,
                myLocationEnabled: _role == 3 && _posicionUsuario != null,
                myLocationButtonEnabled: _role == 3 && _posicionUsuario != null,
                markers: {
                  ..._markers,
                  if (_posicionUsuario != null && _role == 3)
                    Marker(
                      markerId: const MarkerId('mi_ubicacion'),
                      position: _posicionUsuario!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                      infoWindow: const InfoWindow(
                        title: 'Mi ubicación',
                        snippet: 'Estás aquí',
                      ),
                    ),
                },
                circles: _role == 3 && _posicionUsuario != null
                    ? {
                        Circle(
                          circleId: const CircleId('radio_20km'),
                          center: _posicionUsuario!,
                          radius: _radioKm * 1000,
                          strokeColor: _orange,
                          strokeWidth: 2,
                          fillColor: _orange.withValues(alpha: 0.06),
                        ),
                      }
                    : <Circle>{},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_role == 2 && _selected == 'Mis Negocios') {
      return NegociosWeb(usuario: _usuarioActual, embedded: true);
    }
    if (_role == 2 && _selected == 'Galería') {
      return ImagenesWeb(usuario: _usuarioActual, embedded: true);
    }
    if ((_role == 2 || _role == 3) && _selected == 'Mapa') {
      return _section('Mapa', _mapSection());
    }
    if (_selected == 'Configuración de cuenta') {
      return ConfiguracionCuentaWeb(
        usuario: _usuarioActual,
        onActualizado: _actualizarUsuario,
      );
    }
    if (_role == 2 && _selected == 'Mis planes') {
      return MiPlanWeb(embedded: true, onBack: () => _choose('Mi perfil'));
    }
    if (_selected != 'Inicio') {
      return _section(
        _selected,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.construction_outlined, color: _orange, size: 38),
            SizedBox(height: 18),
            Text(
              'Esta sección todavía no está implementada en WAO Web.',
              style: TextStyle(color: _muted, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'No se muestran datos ficticios ni se realizan operaciones.',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      );
    }
    final items = _menu
        .where((x) => x.title != 'Inicio' && x.title != 'Mi perfil')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_side, Color(0xFF2463A5)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2463A5)),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const Positioned(
                right: 8,
                top: -18,
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  size: 110,
                  color: Color(0x30FFFFFF),
                ),
              ),
              const Positioned(
                right: 150,
                bottom: -24,
                child: Icon(
                  Icons.explore_outlined,
                  size: 90,
                  color: Color(0x1FFFFFFF),
                ),
              ),
              const Positioned(
                right: 270,
                top: -10,
                child: Icon(
                  Icons.place_outlined,
                  size: 52,
                  color: Color(0x22FFFFFF),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido, ${_name.split(' ').first}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Accede a tus herramientas de ${_roleName.toLowerCase()} desde un solo lugar.',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_role == 2 || _role == 3) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _choose('Mapa'),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver negocios en el mapa'),
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'Accesos principales',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth >= 980
                ? 3
                : c.maxWidth >= 560
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 165,
              ),
              itemBuilder: (_, i) => _tile(items[i]),
            );
          },
        ),
      ],
    );
  }

  String _profileValue(String key) {
    final value = _usuarioActual[key]?.toString().trim() ?? '';
    return value.isEmpty || value.toLowerCase() == 'null'
        ? 'No disponible'
        : value;
  }

  Widget _profileCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080D2247),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );

  Widget _profileDetail(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEF8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _side, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _profileShortcut(
    IconData icon,
    String title,
    String description,
    String destination,
  ) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => _choose(destination),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _side, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted),
        ],
      ),
    ),
  );

  Widget _profilePage() {
    final email = _profileValue('correo');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mi perfil',
          style: TextStyle(
            color: _ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Consulta tu información personal y administra tu cuenta WAO.',
          style: TextStyle(color: _muted, fontSize: 14),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_side, Color(0xFF2463A5)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              _avatar(39),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color(0xFFE1EBF7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _roleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final details = _profileCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: _side),
                      SizedBox(width: 10),
                      Text(
                        'Información personal',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Datos asociados a tu cuenta.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _profileDetail(
                    Icons.person_outline_rounded,
                    'Nombre',
                    _profileValue('nombre'),
                  ),
                  const SizedBox(height: 12),
                  _profileDetail(
                    Icons.person_outline_rounded,
                    'Apellido',
                    _profileValue('apellido'),
                  ),
                  const SizedBox(height: 12),
                  _profileDetail(
                    Icons.email_outlined,
                    'Correo electrónico',
                    email,
                  ),
                  const SizedBox(height: 12),
                  _profileDetail(
                    Icons.shield_outlined,
                    'Tipo de cuenta',
                    _roleName,
                  ),
                ],
              ),
            );
            final shortcuts = _profileCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: _side),
                      SizedBox(width: 10),
                      Text(
                        'Administrar mi cuenta',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _profileShortcut(
                    Icons.settings_outlined,
                    'Configuración de cuenta',
                    'Opciones y preferencias de la cuenta',
                    'Configuración de cuenta',
                  ),
                  if (_role == 2) ...[
                    const Divider(color: _border),
                    _profileShortcut(
                      Icons.account_balance_outlined,
                      'Cuenta bancaria',
                      'Información para recibir pagos',
                      'Cuenta bancaria',
                    ),
                    const Divider(color: _border),
                    _profileShortcut(
                      Icons.workspace_premium_outlined,
                      'Mis planes',
                      'Consulta las opciones de tu plan',
                      'Mis planes',
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Las opciones aún no implementadas mostrarán un aviso hasta que se conecten sus servicios.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: details),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: shortcuts),
                ],
              );
            }
            return Column(
              children: [details, const SizedBox(height: 18), shortcuts],
            );
          },
        ),
      ],
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 5),
        SelectableText(
          value,
          style: const TextStyle(color: _ink, fontSize: 17),
        ),
      ],
    ),
  );
  Widget _section(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 22),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: child,
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1050;
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Column(
              children: [
                _topBar(desktop),
                Expanded(
                  child:
                      (_role == 2 &&
                          (_selected == 'Mis Negocios' ||
                              _selected == 'Galería' ||
                              _selected == 'Mis planes'))
                      ? _content()
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(desktop ? 32 : 18),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1300),
                              child: _content(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
