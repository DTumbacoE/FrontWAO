import 'package:flutter/material.dart';
import '../Services/Horarios.dart';

const _bg = Color(0xFF081529);
const _panel = Color(0xFF142B50);
const _orange = Color(0xFFF5A623);

/// Vista de horarios: embedded=true permite mostrarla dentro de HomeWeb.
class HorariosWeb extends StatefulWidget {
  final Map<String, dynamic> negocio;
  final bool embedded;
  final VoidCallback? onBack;
  const HorariosWeb({super.key, required this.negocio, this.embedded = false, this.onBack});

  @override
  State<HorariosWeb> createState() => _HorariosWebState();
}

class _HorariosWebState extends State<HorariosWeb> {
  final ApiHorarios _api = ApiHorarios();
  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  List<Map<String, dynamic>> _horarios = [];
  String _dia = 'Todos';
  bool _cargando = true;
  String? _error;

  int? get _idNegocio => int.tryParse('${widget.negocio['id_negocio'] ?? ''}');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = _idNegocio;
    if (id == null) {
      setState(() { _error = 'El negocio no tiene un identificador válido.'; _cargando = false; });
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final respuesta = await _api.obtenerPorNegocio(id);
      if (!mounted) return;
      setState(() {
        _horarios = respuesta.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _cargando = false; _error = 'No se pudieron cargar los horarios.'; });
    }
  }

  String _hora(dynamic value) {
    final texto = '${value ?? ''}';
    final partes = texto.split(':');
    if (partes.length < 2) return texto;
    final h = int.tryParse(partes[0]);
    if (h == null || h < 0 || h > 23) return texto;
    return '${h % 12 == 0 ? 12 : h % 12}:${partes[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }

  TimeOfDay _parse(dynamic value, TimeOfDay fallback) {
    final partes = '${value ?? ''}'.split(':');
    if (partes.length < 2) return fallback;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null || h > 23 || m > 59 || h < 0 || m < 0) return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  String _serialize(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  void _mensaje(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _editar({Map<String, dynamic>? horario}) async {
    String dia = '${horario?['dia_semana'] ?? _dias.first}';
    TimeOfDay apertura = _parse(horario?['hora_apertura'], const TimeOfDay(hour: 8, minute: 0));
    TimeOfDay cierre = _parse(horario?['hora_cierre'], const TimeOfDay(hour: 18, minute: 0));
    bool guardando = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (ctx, update) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(horario == null ? 'Agregar horario' : 'Editar horario', style: const TextStyle(color: Colors.white)),
        content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Día de atención', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dias.contains(dia) ? dia : _dias.first,
            dropdownColor: _panel,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _dias.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: guardando ? null : (value) { if (value != null) update(() => dia = value); },
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 14, runSpacing: 12, children: [
            OutlinedButton.icon(
              onPressed: guardando ? null : () async {
                final result = await showTimePicker(context: ctx, initialTime: apertura);
                if (result != null) update(() => apertura = result);
              },
              icon: const Icon(Icons.login_rounded), label: Text('Apertura: ${apertura.format(ctx)}'),
            ),
            OutlinedButton.icon(
              onPressed: guardando ? null : () async {
                final result = await showTimePicker(context: ctx, initialTime: cierre);
                if (result != null) update(() => cierre = result);
              },
              icon: const Icon(Icons.logout_rounded), label: Text('Cierre: ${cierre.format(ctx)}'),
            ),
          ]),
        ])),
        actions: [
          TextButton(onPressed: guardando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: _bg),
            onPressed: guardando ? null : () async {
              if (apertura.hour * 60 + apertura.minute >= cierre.hour * 60 + cierre.minute) {
                _mensaje('La hora de cierre debe ser posterior a la apertura.');
                return;
              }
              update(() => guardando = true);
              try {
                if (horario == null) {
                  await _api.crearHorario(idNegocio: _idNegocio!, diaSemana: dia,
                    horaApertura: _serialize(apertura), horaCierre: _serialize(cierre));
                } else {
                  final id = int.tryParse('${horario['id_horario']}');
                  if (id == null) throw Exception('Identificador inválido');
                  await _api.actualizarHorario(idHorario: id, diaSemana: dia,
                    horaApertura: _serialize(apertura), horaCierre: _serialize(cierre));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _cargar();
                _mensaje('Horario guardado correctamente.');
              } catch (_) {
                _mensaje('No se pudo guardar el horario.');
                if (ctx.mounted) update(() => guardando = false);
              }
            },
            child: Text(guardando ? 'Guardando...' : 'Guardar'),
          ),
        ],
      )),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> horario) async {
    final confirmar = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Eliminar horario'),
      content: Text('¿Eliminar el horario del ${horario['dia_semana']}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirmar != true) return;
    try {
      final id = int.tryParse('${horario['id_horario']}');
      if (id == null) throw Exception('Identificador inválido');
      await _api.eliminarHorario(id);
      await _cargar();
      _mensaje('Horario eliminado.');
    } catch (_) { _mensaje('No se pudo eliminar el horario.'); }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _dia == 'Todos' ? _horarios : _horarios.where((h) => '${h['dia_semana']}' == _dia).toList();
    final contenido = LayoutBuilder(builder: (context, constraints) {
      final ancho = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
      return SingleChildScrollView(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(padding: EdgeInsets.all(ancho < 650 ? 14 : 28), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 12, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(onPressed: widget.onBack ?? () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), tooltip: 'Volver a mis negocios'),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Horarios de atención', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${widget.negocio['nombre'] ?? 'Negocio'}', style: const TextStyle(color: Colors.white60)),
                ]),
              ]),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(onPressed: _cargando ? null : _cargar, icon: const Icon(Icons.refresh), label: const Text('Actualizar')),
                FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: _bg),
                  onPressed: _idNegocio == null ? null : () => _editar(), icon: const Icon(Icons.add), label: const Text('Agregar horario')),
              ]),
            ]),
            const SizedBox(height: 22),
            Container(width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
              child: Wrap(spacing: 18, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                const Icon(Icons.storefront, color: _orange, size: 30),
                Text('${widget.negocio['nombre'] ?? 'Negocio'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                Text('${_horarios.length} horarios configurados', style: const TextStyle(color: Colors.white60)),
              ])),
            const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: ['Todos', ..._dias].map((d) => ChoiceChip(
              label: Text(d), selected: _dia == d,
              onSelected: (_) => setState(() => _dia = d),
              selectedColor: _orange, backgroundColor: _panel,
              labelStyle: TextStyle(color: _dia == d ? _bg : Colors.white70),
            )).toList()),
            const SizedBox(height: 22),
            if (_cargando) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _orange)))
            else if (_error != null) Center(child: Column(children: [
              Text(_error!, style: const TextStyle(color: Colors.white70)),
              TextButton(onPressed: _cargar, child: const Text('Reintentar')),
            ]))
            else if (filtrados.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Text('No hay horarios registrados para este filtro.', style: TextStyle(color: Colors.white60))))
            else LayoutBuilder(builder: (ctx, size) {
              final columnas = size.maxWidth >= 900 ? 3 : size.maxWidth >= 580 ? 2 : 1;
              final itemWidth = (size.maxWidth - (columnas - 1) * 14) / columnas;
              return Wrap(spacing: 14, runSpacing: 14, children: filtrados.map((h) => SizedBox(width: itemWidth, child: _tarjeta(h))).toList());
            }),
          ],
        )),
      )));
    });
    if (widget.embedded) return contenido;
    return Scaffold(backgroundColor: _bg, body: SafeArea(child: contenido));
  }

  Widget _tarjeta(Map<String, dynamic> horario) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.calendar_month_outlined, color: _orange),
        const SizedBox(width: 10),
        Expanded(child: Text('${horario['dia_semana'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
        IconButton(tooltip: 'Editar', onPressed: () => _editar(horario: horario), icon: const Icon(Icons.edit_outlined, color: Colors.white70)),
        IconButton(tooltip: 'Eliminar', onPressed: () => _eliminar(horario), icon: const Icon(Icons.delete_outline, color: Color(0xFFFF8585))),
      ]),
      const Divider(color: Colors.white12),
      const SizedBox(height: 8),
      Text('Apertura: ${_hora(horario['hora_apertura'])}', style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      Text('Cierre: ${_hora(horario['hora_cierre'])}', style: const TextStyle(color: Colors.white70)),
    ]),
  );
}
