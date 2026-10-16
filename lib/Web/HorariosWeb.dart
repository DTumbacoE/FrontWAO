
import 'package:flutter/material.dart';
import '../Services/Horarios.dart';

const Color _navy = Color(0xFF102C54);
const Color _background = Color(0xFFF5F8FC);
const Color _ink = Color(0xFF102C54);
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE0E8F2);
const Color _orange = Color(0xFFF5A623);
const Color _white = Colors.white;

class HorariosWeb extends StatefulWidget {
  final Map<String, dynamic> negocio;
  final bool embedded;
  final VoidCallback? onBack;

  const HorariosWeb({
    super.key,
    required this.negocio,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<HorariosWeb> createState() => _HorariosWebState();
}

class _HorariosWebState extends State<HorariosWeb> {
  final ApiHorarios _api = ApiHorarios();

  static const List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  List<Map<String, dynamic>> _horarios = [];

  String _dia = 'Todos';
  bool _cargando = true;
  bool _procesando = false;
  String? _error;

  int? get _idNegocio =>
      int.tryParse('${widget.negocio['id_negocio'] ?? ''}');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = _idNegocio;

    if (id == null) {
      setState(() {
        _error = 'El negocio no tiene un identificador válido.';
        _cargando = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final respuesta = await _api.obtenerPorNegocio(id);

      if (!mounted) return;

      final lista = respuesta
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      lista.sort((a, b) {
        final indiceA = _dias.indexOf('${a['dia_semana']}');
        final indiceB = _dias.indexOf('${b['dia_semana']}');

        return (indiceA < 0 ? 99 : indiceA)
            .compareTo(indiceB < 0 ? 99 : indiceB);
      });

      setState(() {
        _horarios = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = 'No se pudieron cargar los horarios.';
      });
    }
  }

  String _hora(dynamic valor) {
    final texto = '${valor ?? ''}';
    final partes = texto.split(':');

    if (partes.length < 2) return texto;

    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);

    if (hora == null ||
        minuto == null ||
        hora < 0 ||
        hora > 23 ||
        minuto < 0 ||
        minuto > 59) {
      return texto;
    }

    final hora12 = hora % 12 == 0 ? 12 : hora % 12;

    return '$hora12:${minuto.toString().padLeft(2, '0')} '
        '${hora >= 12 ? 'PM' : 'AM'}';
  }

  TimeOfDay _parse(
    dynamic valor,
    TimeOfDay fallback,
  ) {
    final partes = '${valor ?? ''}'.split(':');

    if (partes.length < 2) return fallback;

    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);

    if (hora == null ||
        minuto == null ||
        hora < 0 ||
        hora > 23 ||
        minuto < 0 ||
        minuto > 59) {
      return fallback;
    }

    return TimeOfDay(hour: hora, minute: minuto);
  }

  String _serialize(TimeOfDay hora) {
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');

    return '$h:$m:00';
  }

  int _minutos(TimeOfDay hora) {
    return hora.hour * 60 + hora.minute;
  }

  void _mensaje(
    String texto, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error
            ? const Color(0xFFB42318)
            : const Color(0xFF16876D),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editar({
    Map<String, dynamic>? horario,
  }) async {
    if (_procesando || _idNegocio == null) return;

    String dia = '${horario?['dia_semana'] ?? _dias.first}';

    if (!_dias.contains(dia)) {
      dia = _dias.first;
    }

    TimeOfDay apertura = _parse(
      horario?['hora_apertura'],
      const TimeOfDay(hour: 8, minute: 0),
    );

    TimeOfDay cierre = _parse(
      horario?['hora_cierre'],
      const TimeOfDay(hour: 18, minute: 0),
    );

    bool guardando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, actualizar) {
            return AlertDialog(
              backgroundColor: _white,
              surfaceTintColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E3),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      horario == null
                          ? Icons.add_circle_outline_rounded
                          : Icons.edit_calendar_rounded,
                      color: _orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      horario == null
                          ? 'Agregar horario'
                          : 'Editar horario',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Día de atención',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String>(
                      value: dia,
                      isExpanded: true,
                      dropdownColor: _white,
                      style: const TextStyle(color: _ink),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: _muted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _dias
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ),
                          )
                          .toList(),
                      onChanged: guardando
                          ? null
                          : (valor) {
                              if (valor != null) {
                                actualizar(() => dia = valor);
                              }
                            },
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Horario de atención',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _botonHora(
                          'Apertura',
                          apertura,
                          guardando
                              ? null
                              : () async {
                                  final seleccion = await showTimePicker(
                                    context: ctx,
                                    initialTime: apertura,
                                  );

                                  if (seleccion != null && ctx.mounted) {
                                    actualizar(
                                      () => apertura = seleccion,
                                    );
                                  }
                                },
                        ),
                        _botonHora(
                          'Cierre',
                          cierre,
                          guardando
                              ? null
                              : () async {
                                  final seleccion = await showTimePicker(
                                    context: ctx,
                                    initialTime: cierre,
                                  );

                                  if (seleccion != null && ctx.mounted) {
                                    actualizar(
                                      () => cierre = seleccion,
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),
              actions: [
                OutlinedButton(
                  onPressed: guardando
                      ? null
                      : () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _line),
                  ),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (_minutos(apertura) >= _minutos(cierre)) {
                            _mensaje(
                              'La hora de cierre debe ser posterior a la apertura.',
                              error: true,
                            );
                            return;
                          }

                          final idHorario = horario == null
                              ? null
                              : int.tryParse(
                                  '${horario['id_horario']}',
                                );

                          if (horario != null && idHorario == null) {
                            _mensaje(
                              'El horario no tiene un identificador válido.',
                              error: true,
                            );
                            return;
                          }

                          actualizar(() => guardando = true);

                          try {
                            Map<String, dynamic>? resultado;

                            if (horario == null) {
                              resultado = await _api.crearHorario(
                                idNegocio: _idNegocio!,
                                diaSemana: dia,
                                horaApertura: _serialize(apertura),
                                horaCierre: _serialize(cierre),
                              );
                            } else {
                              resultado = await _api.actualizarHorario(
                                idHorario: idHorario!,
                                diaSemana: dia,
                                horaApertura: _serialize(apertura),
                                horaCierre: _serialize(cierre),
                              );
                            }

                            if (!ctx.mounted) return;

                            if (resultado == null ||
                                resultado['success'] == false) {
                              _mensaje(
                                resultado?['message']?.toString() ??
                                    'No se pudo guardar el horario.',
                                error: true,
                              );
                              actualizar(() => guardando = false);
                              return;
                            }

                            Navigator.pop(ctx);

                            await _cargar();

                            _mensaje(
                              'Horario guardado correctamente.',
                            );
                          } catch (e) {
                            _mensaje(
                              'No se pudo guardar el horario.',
                              error: true,
                            );

                            if (ctx.mounted) {
                              actualizar(() => guardando = false);
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: _navy,
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    guardando ? 'Guardando...' : 'Guardar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _botonHora(
    String etiqueta,
    TimeOfDay hora,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.access_time_rounded,
        size: 18,
      ),
      label: Text(
        '$etiqueta: ${hora.format(context)}',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _navy,
        side: const BorderSide(color: _line),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
    );
  }

  Future<void> _eliminar(
    Map<String, dynamic> horario,
  ) async {
    if (_procesando) return;

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
            'Eliminar horario',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '¿Deseas eliminar el horario del ${horario['dia_semana']}?',
            style: const TextStyle(color: _muted),
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
      '${horario['id_horario']}',
    );

    if (id == null) {
      _mensaje(
        'Identificador de horario inválido.',
        error: true,
      );
      return;
    }

    setState(() => _procesando = true);

    try {
      final eliminado = await _api.eliminarHorario(id);

      if (!mounted) return;

      if (!eliminado) {
        _mensaje(
          'No se pudo eliminar el horario.',
          error: true,
        );
        return;
      }

      await _cargar();

      _mensaje('Horario eliminado correctamente.');
    } catch (e) {
      _mensaje(
        'No se pudo eliminar el horario.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Widget _encabezado(bool compacto) {
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
                'Horarios de atención',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${widget.negocio['nombre'] ?? 'Negocio'}',
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
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _idNegocio == null || _procesando
              ? null
              : () => _editar(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar horario'),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: _navy,
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15,
            ),
          ),
        ),
      ],
    );

    if (compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,
          const SizedBox(height: 15),
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

  Widget _resumen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: _orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.negocio['nombre'] ?? 'Negocio'}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Gestiona los días y horas de atención',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${_horarios.length}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Horarios',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Wrap(
      spacing: 8,
      runSpacing: 9,
      children: ['Todos', ..._dias].map((dia) {
        final seleccionado = _dia == dia;

        return ChoiceChip(
          label: Text(dia),
          selected: seleccionado,
          onSelected: (_) {
            setState(() => _dia = dia);
          },
          selectedColor: _navy,
          backgroundColor: _white,
          side: BorderSide(
            color: seleccionado ? _navy : _line,
          ),
          labelStyle: TextStyle(
            color: seleccionado ? _white : _navy,
            fontWeight: seleccionado
                ? FontWeight.w700
                : FontWeight.w500,
          ),
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget _tarjeta(Map<String, dynamic> horario) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: _orange,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${horario['dia_semana'] ?? ''}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: _procesando
                    ? null
                    : () => _editar(horario: horario),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _navy,
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: _procesando
                    ? null
                    : () => _eliminar(horario),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB42318),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 17),

          _filaHora(
            'Apertura',
            _hora(horario['hora_apertura']),
            Icons.login_rounded,
          ),

          const SizedBox(height: 13),

          _filaHora(
            'Cierre',
            _hora(horario['hora_cierre']),
            Icons.logout_rounded,
          ),
        ],
      ),
    );
  }

  Widget _filaHora(
    String etiqueta,
    String valor,
    IconData icono,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          color: _muted,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            etiqueta,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _dia == 'Todos'
        ? _horarios
        : _horarios
            .where(
              (horario) =>
                  '${horario['dia_semana']}' == _dia,
            )
            .toList();

    final contenido = LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final compacto = ancho < 850;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1250,
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  ancho < 650 ? 16 : 28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _encabezado(compacto),

                    const SizedBox(height: 22),

                    _resumen(),

                    const SizedBox(height: 24),

                    const Text(
                      'Filtrar por día',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _filtros(),

                    const SizedBox(height: 25),

                    if (_cargando)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(45),
                          child: CircularProgressIndicator(
                            color: _orange,
                          ),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _cargar,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    else if (filtrados.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 60,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_busy_outlined,
                                size: 48,
                                color: _muted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No hay horarios registrados para este filtro.',
                                style: TextStyle(
                                  color: _muted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, size) {
                          final columnas =
                              size.maxWidth >= 900
                                  ? 3
                                  : size.maxWidth >= 580
                                      ? 2
                                      : 1;

                          const espacio = 14.0;

                          final anchoTarjeta =
                              (size.maxWidth -
                                      (columnas - 1) * espacio) /
                                  columnas;

                          return Wrap(
                            spacing: espacio,
                            runSpacing: espacio,
                            children: filtrados
                                .map(
                                  (horario) => SizedBox(
                                    width: anchoTarjeta,
                                    child: _tarjeta(horario),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                  ],
                ),
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
}
