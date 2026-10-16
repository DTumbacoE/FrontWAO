import 'package:flutter/material.dart';
import '../Services/Negocio.dart';

const _bg = Color(0xFFF5F8FC);
const _navy = Color(0xFF102C54);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE0E8F2);
const _orange = Color(0xFFF5A623);
const _green = Color(0xFF16876D);
const _red = Color(0xFFB42318);

class MiPlanWeb extends StatefulWidget {
  final int? idNegocio;
  final bool embedded;
  final VoidCallback? onBack;

  const MiPlanWeb({
    super.key,
    this.idNegocio,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<MiPlanWeb> createState() => _MiPlanWebState();
}

class _MiPlanWebState extends State<MiPlanWeb> {
  final ApiNegocio _api = ApiNegocio();
  List<Map<String, dynamic>> _items = [];
  int? _seleccionado;
  bool _cargando = true;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant MiPlanWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idNegocio != widget.idNegocio) _cargar();
  }

  int? _id(dynamic value) => int.tryParse('${value ?? ''}');
  String _texto(dynamic value, [String defecto = '—']) {
    final s = '${value ?? ''}'.trim();
    return s.isEmpty || s == 'null' ? defecto : s;
  }

  bool _activo(dynamic value) =>
      value == true || value == 1 ||
      '${value ?? ''}'.toLowerCase() == 'true' || '$value' == '1';

  Future<void> _cargar() async {
    final version = ++_version;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // El servidor debe limitar esta lista al usuario autenticado.
      final negocios = await _api.misNegocios();
      final filtrados = negocios.where((n) {
        final id = _id(n['id_negocio']);
        return id != null &&
            (widget.idNegocio == null || id == widget.idNegocio);
      }).toList();

      final resultados = await Future.wait(filtrados.map((negocio) async {
        final id = _id(negocio['id_negocio'])!;
        try {
          final plan = await _api.obtenerPlan(id);
          return <String, dynamic>{
            'id': id,
            'negocio': Map<String, dynamic>.from(negocio),
            'plan': plan,
            'error': false,
          };
        } catch (_) {
          return <String, dynamic>{
            'id': id,
            'negocio': Map<String, dynamic>.from(negocio),
            'plan': null,
            'error': true,
          };
        }
      }));
      if (!mounted || version != _version) return;
      setState(() {
        _items = resultados;
        if (!_items.any((e) => e['id'] == _seleccionado)) {
          _seleccionado = _items.isEmpty ? null : _items.first['id'] as int;
        }
        _cargando = false;
      });
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() {
        _error = 'No se pudieron obtener los negocios del propietario.';
        _cargando = false;
      });
    }
  }

  Map<String, dynamic>? get _actual {
    for (final item in _items) {
      if (item['id'] == _seleccionado) return item;
    }
    return null;
  }

  BoxDecoration _decoracion() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: _border),
    boxShadow: const [
      BoxShadow(color: Color(0x08102C54), blurRadius: 14, offset: Offset(0, 4)),
    ],
  );

  Widget _etiqueta(String texto, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );

  Widget _tarjetaNegocio(Map<String, dynamic> item) {
    final negocio = item['negocio'] as Map<String, dynamic>;
    final plan = item['plan'] as Map<String, dynamic>?;
    final seleccionado = item['id'] == _seleccionado;
    final error = item['error'] == true;
    final estado = error ? 'Error de consulta' : plan == null
        ? 'Sin plan' : _activo(plan['activo']) ? 'Activo' : 'Inactivo';
    final color = error ? _red : plan == null ? _muted :
        _activo(plan['activo']) ? _green : _red;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _seleccionado = item['id'] as int),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: _decoracion().copyWith(
          border: Border.all(color: seleccionado ? _orange : _border, width: seleccionado ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: const Color(0xFFFFF4E3), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_outlined, color: _orange),
              ),
              const Spacer(),
              if (seleccionado) const Icon(Icons.check_circle, color: _orange),
            ]),
            const SizedBox(height: 14),
            Text(_texto(negocio['nombre'], 'Negocio sin nombre'),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('Plan: ${_texto(plan?['nombre'], error ? 'No disponible' : 'Sin asignar')}',
                style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            _etiqueta(estado, color),
            const SizedBox(height: 15),
            const Row(children: [
              Text('Ver detalles', style: TextStyle(color: _navy, fontWeight: FontWeight.w700)),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward_rounded, color: _orange, size: 18),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String titulo, String valor) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
    child: Row(children: [
      Icon(icono, color: _orange, size: 21),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w800)),
      ])),
    ]),
  );

  Widget _detalle() {
    final item = _actual;
    if (item == null) return const SizedBox.shrink();
    final negocio = item['negocio'] as Map<String, dynamic>;
    final plan = item['plan'] as Map<String, dynamic>?;
    final error = item['error'] == true;
    final beneficios = plan?['beneficios'] is List
        ? (plan!['beneficios'] as List).whereType<Map>().toList()
        : <Map>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _decoracion(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DETALLES DEL PLAN', style: TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 7),
        Text(_texto(negocio['nombre']), style: const TextStyle(color: _navy, fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 15),
        if (error)
          const Text('No se pudo consultar el plan de este negocio. Pulsa Actualizar para reintentar.',
              style: TextStyle(color: _red))
        else if (plan == null)
          const Text('Este negocio no tiene información de plan disponible.',
              style: TextStyle(color: _muted))
        else ...[
          Row(children: [
            Expanded(child: Text(_texto(plan['nombre'], 'Plan'),
                style: const TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800))),
            _etiqueta(_activo(plan['activo']) ? 'Activo' : 'Inactivo',
                _activo(plan['activo']) ? _green : _red),
          ]),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, c) {
            final datos = [
              _dato(Icons.event_outlined, 'Vencimiento', _texto(plan['fecha_vencimiento'])),
              _dato(Icons.hourglass_bottom_outlined, 'Días restantes',
                  plan['dias_restantes'] == null ? '—' : '${plan['dias_restantes']} días'),
              _dato(Icons.payments_outlined, 'Precio',
                  plan['precio'] == null ? '—' : '\$${plan['precio']}'),
              _dato(Icons.storefront_outlined, 'Límite de negocios', _texto(plan['limite_negocios'])),
            ];
            final ancho = c.maxWidth;
            return Wrap(spacing: 12, runSpacing: 12,
              children: datos.map((dato) => SizedBox(
                width: ancho >= 600 ? (ancho - 12) / 2 : ancho,
                child: dato,
              )).toList());
          }),
          const SizedBox(height: 22),
          const Text('Beneficios incluidos', style: TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (beneficios.isEmpty)
            const Text('El servicio no proporcionó beneficios para este plan.',
                style: TextStyle(color: _muted))
          else
            ...beneficios.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_activo(b['activo']) ? Icons.check_circle_outline : Icons.lock_outline,
                    color: _activo(b['activo']) ? _green : _muted, size: 21),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_texto(b['nombre'], 'Beneficio'),
                      style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
                  if (_texto(b['descripcion'], '').isNotEmpty)
                    Text(_texto(b['descripcion']), style: const TextStyle(color: _muted, fontSize: 12)),
                ])),
              ]),
            )),
        ],
      ]),
    );
  }

  Widget _contenido() => LayoutBuilder(builder: (context, constraints) {
    final compacto = constraints.maxWidth < 680;
    return SingleChildScrollView(
      padding: EdgeInsets.all(compacto ? 16 : 28),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1150),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(
              tooltip: 'Volver',
              onPressed: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: _navy),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mis planes', style: TextStyle(color: _navy, fontSize: 27, fontWeight: FontWeight.w800)),
              SizedBox(height: 5),
              Text('Planes de todos tus negocios registrados', style: TextStyle(color: _muted)),
            ])),
            IconButton(tooltip: 'Actualizar', onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.refresh_rounded, color: _navy)),
          ]),
          const SizedBox(height: 23),
          if (_cargando)
            const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: _orange)))
          else if (_error != null)
            Column(children: [
              Text(_error!, style: const TextStyle(color: _red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
            ])
          else if (_items.isEmpty)
            Container(width: double.infinity, padding: const EdgeInsets.all(30),
              decoration: _decoracion(),
              child: const Text('No se encontraron negocios asociados a tu cuenta.',
                  style: TextStyle(color: _muted)))
          else ...[
            Text('${_items.length} negocio(s) registrado(s)',
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
            const SizedBox(height: 15),
            LayoutBuilder(builder: (context, c) {
              final ancho = c.maxWidth;
              final columnas = ancho >= 900 ? 3 : ancho >= 560 ? 2 : 1;
              final anchoCard = (ancho - (columnas - 1) * 14) / columnas;
              return Wrap(spacing: 14, runSpacing: 14,
                children: _items.map((item) => SizedBox(width: anchoCard, child: _tarjetaNegocio(item))).toList());
            }),
            const SizedBox(height: 24),
            _detalle(),
          ],
        ]),
      )),
    );
  });

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return ColoredBox(color: _bg, child: _contenido());
    return Scaffold(backgroundColor: _bg, body: SafeArea(child: _contenido()));
  }
}
