import 'package:flutter/material.dart';
import '../Services/Negocio.dart';

const Color _bg = Color(0xFFF5F8FC);
const Color _white = Colors.white;
const Color _navy = Color(0xFF102C54);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE0E8F2);
const Color _orange = Color(0xFFF5A623);
const Color _orangeLight = Color(0xFFFFF4E3);
const Color _green = Color(0xFF16876D);
const Color _red = Color(0xFFB42318);

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

  @override
  void didUpdateWidget(covariant MiPlanWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.idNegocio != widget.idNegocio) {
      _cargar();
    }
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    final idSolicitado = widget.idNegocio;

    setState(() {
      _cargando = true;
      _error = null;
      _plan = null;
    });

    try {
      final data = await _api.obtenerPlan(idSolicitado);

      if (!mounted || widget.idNegocio != idSolicitado) {
        return;
      }

      setState(() {
        _plan = data;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || widget.idNegocio != idSolicitado) {
        return;
      }

      setState(() {
        _error = 'No fue posible consultar la información del plan.';
        _cargando = false;
      });
    }
  }

  String _valor(String campo, [String alternativa = '—']) {
    final valor = _plan?[campo];

    if (valor == null || '$valor'.trim().isEmpty) {
      return alternativa;
    }

    return '$valor';
  }

  int _entero(String campo, [int alternativa = 0]) {
    final valor = _plan?[campo];

    if (valor is num) {
      return valor.toInt();
    }

    return int.tryParse('$valor') ?? alternativa;
  }

  bool _activo(dynamic valor) {
    return valor == true ||
        valor == 1 ||
        '$valor'.toLowerCase() == 'true' ||
        '$valor' == '1';
  }

  void _volver() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenido = LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 680;

        return SingleChildScrollView(
          padding: EdgeInsets.all(compacto ? 16 : 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezado(compacto),

                  const SizedBox(height: 24),

                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(color: _orange),
                      ),
                    )
                  else if (_error != null)
                    _estado(
                      Icons.wifi_off_rounded,
                      'No se pudo cargar el plan',
                      _error!,
                      'Reintentar',
                      _cargar,
                    )
                  else if (_plan == null)
                    _estado(
                      Icons.workspace_premium_outlined,
                      'Sin plan asignado',
                      'Este negocio todavía no tiene un plan disponible.',
                      'Actualizar',
                      _cargar,
                    )
                  else ...[
                    _resumen(compacto),
                    const SizedBox(height: 20),
                    _progreso(),
                    const SizedBox(height: 26),
                    _beneficios(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(color: _bg, child: contenido);
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: contenido),
    );
  }

  Widget _encabezado(bool compacto) {
    final titulo = Row(
      children: [
        IconButton(
          tooltip: 'Volver a mis negocios',
          onPressed: _volver,
          icon: const Icon(Icons.arrow_back_rounded, color: _navy),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi plan',
                style: TextStyle(
                  color: _navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Información de la suscripción del negocio',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
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
        side: const BorderSide(color: _border),
        backgroundColor: _white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 14), actualizar],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),
        actualizar,
      ],
    );
  }

  Widget _resumen(bool compacto) {
    final activo = _activo(_plan?['activo']);
    final nombre = _valor('nombre', 'Plan');

    final precio = _plan?['precio'] == null ? '—' : '\$${_plan!['precio']}/mes';

    final totalNegocios = _entero('total_negocios');
    final limite = _entero('limite_negocios');

    final estadisticas = <Widget>[
      _stat(Icons.event_rounded, 'Vencimiento', _valor('fecha_vencimiento')),
      _stat(
        Icons.hourglass_bottom_rounded,
        'Días restantes',
        '${_entero('dias_restantes')} días',
      ),
      _stat(Icons.payments_outlined, 'Costo del plan', precio),
      _stat(
        Icons.storefront_outlined,
        'Negocios',
        limite > 0 ? '$totalNegocios de $limite' : '$totalNegocios',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? 18 : 26),
      decoration: _decoracion(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _orange,
                  size: 34,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLAN ACTUAL',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFFE7F6F1)
                      : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activo
                          ? Icons.check_circle_rounded
                          : Icons.cancel_outlined,
                      size: 15,
                      color: activo ? _green : _red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activo ? 'ACTIVO' : 'INACTIVO',
                      style: TextStyle(
                        color: activo ? _green : _red,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 23),
          const Divider(color: _border),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth < 520 ? 1 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnas,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 94,
                ),

                itemCount: estadisticas.length,

                itemBuilder: (context, index) {
                  return estadisticas[index];
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icono, String etiqueta, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icono, color: _orange, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progreso() {
    final total = _entero('total_dias', 30);
    final restantes = _entero('dias_restantes');

    final progreso = total > 0
        ? ((total - restantes) / total).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: _decoracion(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: _orange,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ciclo de facturación',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progreso * 100).round()}%',
                style: const TextStyle(
                  color: _orange,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 9,
              color: _orange,
              backgroundColor: _border,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Progreso del período de suscripción',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _beneficios() {
    final raw = _plan?['beneficios'];

    final beneficios = raw is List ? raw.whereType<Map>().toList() : <Map>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BENEFICIOS DEL PLAN',
          style: TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),

        if (beneficios.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _decoracion(),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'El servicio no ha proporcionado un listado de beneficios para este plan.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;

              final anchoTarjeta = ancho >= 750 ? (ancho - 14) / 2 : ancho;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: beneficios.map((beneficio) {
                  final activo = _activo(beneficio['activo']);

                  return SizedBox(
                    width: anchoTarjeta,
                    child: Container(
                      padding: const EdgeInsets.all(19),
                      decoration: _decoracion(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: activo ? const Color(0xFFE7F6F1) : _bg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              activo
                                  ? Icons.check_circle_rounded
                                  : Icons.lock_outline_rounded,
                              color: activo ? _green : _muted,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${beneficio['nombre'] ?? 'Beneficio'}',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if ('${beneficio['descripcion'] ?? ''}'
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${beneficio['descripcion']}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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

  Widget _estado(
    IconData icono,
    String titulo,
    String mensaje,
    String boton,
    VoidCallback accion,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: _decoracion(),
      child: Column(
        children: [
          Icon(icono, size: 47, color: _orange),
          const SizedBox(height: 13),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: accion,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(boton),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoracion() {
    return BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07102C54),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
