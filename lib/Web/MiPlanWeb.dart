import 'package:flutter/material.dart';
import '../Services/Negocio.dart';

const Color _bg = Color(0xFF081529);
const Color _panel = Color(0xFF142B50);
const Color _orange = Color(0xFFF5A623);

/// Mi Plan para escritorio y móvil web. Dentro de HomeWeb usar embedded: true.
class MiPlanWeb extends StatefulWidget {
  final int idNegocio;
  final bool embedded;
  final VoidCallback? onBack;

  const MiPlanWeb({
    super.key,
    required this.idNegocio,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<MiPlanWeb> createState() => _MiPlanWebState();
}

class _MiPlanWebState extends State<MiPlanWeb> {
  final ApiNegocio _api = ApiNegocio();
  Map<String, dynamic>? _plan;
  bool _cargando = true;
  String? _error;

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
      final data = await _api.obtenerPlan(widget.idNegocio);
      if (!mounted) return;
      setState(() {
        _plan = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  String _valor(String campo, [String alternativa = '—']) {
    final v = _plan?[campo];
    return v == null || '$v'.trim().isEmpty ? alternativa : '$v';
  }

  int _entero(String campo, [int alternativa = 0]) =>
      int.tryParse('${_plan?[campo] ?? ''}') ?? alternativa;

  bool _activo(dynamic v) => v == true || v == 1 || '$v'.toLowerCase() == 'true';

  void _volver() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(builder: (context, constraints) {
      final compacto = constraints.maxWidth < 680;
      return SingleChildScrollView(
        padding: EdgeInsets.all(compacto ? 16 : 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(
                  tooltip: 'Volver a mis negocios',
                  onPressed: _volver,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mi plan', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Información de la suscripción del negocio', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ])),
                IconButton(
                  tooltip: 'Actualizar plan',
                  onPressed: _cargando ? null : _cargar,
                  icon: const Icon(Icons.refresh_rounded, color: _orange),
                ),
              ]),
              const SizedBox(height: 24),
              if (_cargando)
                const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: _orange)))
              else if (_error != null)
                _estado(Icons.wifi_off_rounded, 'No se pudo cargar el plan', _error!, 'Reintentar', _cargar)
              else if (_plan == null)
                _estado(Icons.workspace_premium_outlined, 'Sin plan asignado',
                    'Este negocio todavía no tiene un plan disponible.', 'Actualizar', _cargar)
              else ...[
                _resumen(compacto),
                const SizedBox(height: 20),
                _progreso(),
                const SizedBox(height: 24),
                _beneficios(),
              ],
            ]),
          ),
        ),
      );
    });
    if (widget.embedded) return content;
    return Scaffold(backgroundColor: _bg, body: SafeArea(child: content));
  }

  Widget _resumen(bool compacto) {
    final activo = _activo(_plan?['activo']);
    final nombre = _valor('nombre', 'Plan');
    final precio = _plan?['precio'] == null ? '—' : '\$${_plan!['precio']}/mes';
    final totalNegocios = _entero('total_negocios');
    final limite = _entero('limite_negocios');
    final stats = <Widget>[
      _stat(Icons.event_rounded, 'Vencimiento', _valor('fecha_vencimiento')),
      _stat(Icons.hourglass_bottom_rounded, 'Días restantes', '${_entero('dias_restantes')} días'),
      _stat(Icons.payments_outlined, 'Costo', precio),
      _stat(Icons.storefront_outlined, 'Negocios', limite > 0 ? '$totalNegocios de $limite' : '$totalNegocios'),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? 18 : 28),
      decoration: _decoracion(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 14, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Icon(Icons.workspace_premium_rounded, color: _orange, size: 39),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PLAN ACTUAL', style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: (activo ? Colors.green : Colors.red).withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(activo ? 'ACTIVO' : 'INACTIVO',
                style: TextStyle(color: activo ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 22),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final columnas = c.maxWidth < 520 ? 1 : 2;
          return GridView.count(
            crossAxisCount: columnas,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columnas == 1 ? 5 : 3.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: stats,
          );
        }),
      ]),
    );
  }

  Widget _stat(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
      Row(children: [
        Icon(icon, color: Colors.white54, size: 15),
        const SizedBox(width: 7),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12))),
      ]),
      const SizedBox(height: 6),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _progreso() {
    final total = _entero('total_dias', 30);
    final restantes = _entero('dias_restantes');
    final progreso = total > 0 ? ((total - restantes) / total).clamp(0.0, 1.0).toDouble() : 0.0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _decoracion(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Ciclo de facturación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text('${(progreso * 100).round()}%', style: const TextStyle(color: _orange, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
          value: progreso, minHeight: 9, color: _orange, backgroundColor: Colors.white12,
        )),
      ]),
    );
  }

  Widget _beneficios() {
    final raw = _plan?['beneficios'];
    final beneficios = raw is List ? raw.whereType<Map>().toList() : <Map>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('BENEFICIOS DEL PLAN', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 12),
      if (beneficios.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _decoracion(),
          child: const Text('El servicio no ha proporcionado un listado de beneficios para este plan.',
              style: TextStyle(color: Colors.white60)),
        )
      else
        LayoutBuilder(builder: (context, c) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: beneficios.map((b) {
            final activo = _activo(b['activo']);
            return SizedBox(
              width: c.maxWidth >= 750 ? (c.maxWidth - 12) / 2 : c.maxWidth,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: _decoracion(),
                child: Row(children: [
                  Icon(activo ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      color: activo ? _orange : Colors.white38),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b['nombre'] ?? 'Beneficio'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if ('${b['descripcion'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('${b['descripcion']}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ])),
                ]),
              ),
            );
          }).toList(),
        )),
    ]);
  }

  Widget _estado(IconData icon, String titulo, String mensaje, String boton, VoidCallback accion) =>
      Center(child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: _decoracion(),
        child: Column(children: [
          Icon(icon, size: 46, color: _orange),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: accion, child: Text(boton)),
        ]),
      ));

  BoxDecoration _decoracion() => BoxDecoration(
    color: _panel,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.white12),
  );
}
