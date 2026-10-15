import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../Services/Usuarios.dart';

const _navy = Color(0xFF102C54);
const _blue = Color(0xFF2463A5);
const _orange = Color(0xFFF5A623);
const _border = Color(0xFFE0E8F2);

class ConfiguracionCuentaWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final ValueChanged<Map<String, dynamic>> onActualizado;

  const ConfiguracionCuentaWeb({
    super.key,
    required this.usuario,
    required this.onActualizado,
  });

  @override
  State<ConfiguracionCuentaWeb> createState() => _ConfiguracionCuentaWebState();
}

class _ConfiguracionCuentaWebState extends State<ConfiguracionCuentaWeb> {
  final _api = ApiUsuario();
  final _datosKey = GlobalKey<FormState>();
  final _claveKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _guardando = false;
  bool _fotoCargando = false;
  bool _claveCargando = false;
  bool _ocultarActual = true;
  bool _ocultarNueva = true;
  bool _ocultarConfirmacion = true;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _cargarCampos();
  }

  void _cargarCampos() {
    _nombre.text = widget.usuario['nombre']?.toString() ?? '';
    _apellido.text = widget.usuario['apellido']?.toString() ?? '';
    _telefono.text = widget.usuario['telefono']?.toString() ?? '';
    _direccion.text = widget.usuario['direccion']?.toString() ?? '';
    _fotoUrl = widget.usuario['foto_perfil_url']?.toString();
  }

  @override
  void didUpdateWidget(covariant ConfiguracionCuentaWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario['id_usuario'] != widget.usuario['id_usuario']) {
      _cargarCampos();
    } else {
      _fotoUrl = widget.usuario['foto_perfil_url']?.toString();
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _apellido,
      _telefono,
      _direccion,
      _actual,
      _nueva,
      _confirmacion,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _mensaje(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? const Color(0xFFB53D45) : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _guardarDatos() async {
    if (_guardando || !_datosKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final respuesta = await _api.editarPerfil(
      nombre: _nombre.text,
      apellido: _apellido.text,
      telefono: _telefono.text,
      direccion: _direccion.text,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (respuesta['success'] == true && respuesta['usuario'] is Map) {
      widget.onActualizado(Map<String, dynamic>.from(respuesta['usuario']));
      _mensaje('Información personal actualizada');
    } else {
      _mensaje(
        respuesta['message']?.toString() ?? 'No se pudieron guardar los datos',
        error: true,
      );
    }
  }

  Future<void> _subirFoto() async {
    if (_fotoCargando) return;
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (resultado == null || resultado.files.isEmpty) return;
      final archivo = resultado.files.single;
      final Uint8List? bytes = archivo.bytes;
      if (bytes == null || bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        _mensaje('Selecciona una imagen válida de hasta 5 MB', error: true);
        return;
      }
      setState(() => _fotoCargando = true);
      final respuesta = await _api.subirFotoPerfil(
        bytes: bytes,
        nombreArchivo: archivo.name,
      );
      if (!mounted) return;
      if (respuesta['success'] == true) {
        final url = respuesta['foto_perfil_url']?.toString();
        setState(() => _fotoUrl = url);
        widget.onActualizado({'foto_perfil_url': url});
        _mensaje('Foto de perfil actualizada');
      } else {
        _mensaje(
          respuesta['message']?.toString() ?? 'No se pudo subir la imagen',
          error: true,
        );
      }
    } catch (_) {
      _mensaje('No se pudo seleccionar o subir la imagen', error: true);
    } finally {
      if (mounted) setState(() => _fotoCargando = false);
    }
  }

  Future<void> _eliminarFoto() async {
    if (_fotoCargando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _fotoCargando = true);
    final respuesta = await _api.eliminarFotoPerfil();
    if (!mounted) return;
    setState(() => _fotoCargando = false);
    if (respuesta['success'] == true) {
      setState(() => _fotoUrl = null);
      widget.onActualizado({'foto_perfil_url': null});
      _mensaje('Foto eliminada');
    } else {
      _mensaje(
        respuesta['message']?.toString() ?? 'No se pudo eliminar la foto',
        error: true,
      );
    }
  }

  Future<void> _cambiarClave() async {
    if (_claveCargando || !_claveKey.currentState!.validate()) return;
    setState(() => _claveCargando = true);
    final respuesta = await _api.cambiarContrasena(
      contrasenaActual: _actual.text,
      contrasenaNueva: _nueva.text,
    );
    if (!mounted) return;
    setState(() => _claveCargando = false);
    if (respuesta['success'] == true) {
      _actual.clear();
      _nueva.clear();
      _confirmacion.clear();
      _mensaje('Contraseña actualizada correctamente');
    } else {
      _mensaje(
        respuesta['message']?.toString() ?? 'No se pudo cambiar la contraseña',
        error: true,
      );
    }
  }

  InputDecoration _decoracion(
    String titulo, {
    IconData? icono,
    Widget? sufijo,
  }) => InputDecoration(
    labelText: titulo,
    prefixIcon: icono == null ? null : Icon(icono, color: _blue),
    suffixIcon: sufijo,
    filled: true,
    fillColor: const Color(0xFFF5F8FC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );

  Widget _tarjeta(String titulo, IconData icono, Widget contenido) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: _navy),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        contenido,
      ],
    ),
  );

  Widget _campo(
    TextEditingController controller,
    String titulo,
    IconData icono, {
    int max = 100,
    bool requerido = false,
  }) => TextFormField(
    controller: controller,
    maxLength: max,
    decoration: _decoracion(titulo, icono: icono).copyWith(counterText: ''),
    validator: (v) => requerido && (v == null || v.trim().isEmpty)
        ? 'Este campo es obligatorio'
        : null,
  );

  Widget _campoClave(
    TextEditingController controller,
    String titulo,
    bool ocultar,
    VoidCallback cambiar,
    String? Function(String?) validator,
  ) => TextFormField(
    controller: controller,
    obscureText: ocultar,
    autocorrect: false,
    enableSuggestions: false,
    decoration: _decoracion(
      titulo,
      icono: Icons.lock_outline,
      sufijo: IconButton(
        onPressed: cambiar,
        icon: Icon(
          ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    final foto = _fotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuración de cuenta',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Actualiza tus datos personales, fotografía y contraseña.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 22),
        _tarjeta(
          'Foto de perfil',
          Icons.account_circle_outlined,
          Wrap(
            spacing: 18,
            runSpacing: 14,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: _orange,
                backgroundImage: foto != null && foto.startsWith('https://')
                    ? NetworkImage(foto)
                    : null,
                child: foto != null && foto.startsWith('https://')
                    ? null
                    : const Icon(Icons.person, color: _navy, size: 44),
              ),
              OutlinedButton.icon(
                onPressed: _fotoCargando ? null : _subirFoto,
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Subir o cambiar foto'),
              ),
              if (foto != null && foto.isNotEmpty)
                TextButton.icon(
                  onPressed: _fotoCargando ? null : _eliminarFoto,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar foto'),
                ),
              if (_fotoCargando) const CircularProgressIndicator(),
              const Text(
                'JPG, PNG o WebP · Máximo 5 MB',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _tarjeta(
          'Información personal',
          Icons.badge_outlined,
          Form(
            key: _datosKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, c) => c.maxWidth >= 620
                      ? Row(
                          children: [
                            Expanded(
                              child: _campo(
                                _nombre,
                                'Nombre',
                                Icons.person_outline,
                                requerido: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _campo(
                                _apellido,
                                'Apellido',
                                Icons.person_outline,
                                requerido: true,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _campo(
                              _nombre,
                              'Nombre',
                              Icons.person_outline,
                              requerido: true,
                            ),
                            const SizedBox(height: 14),
                            _campo(
                              _apellido,
                              'Apellido',
                              Icons.person_outline,
                              requerido: true,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: widget.usuario['correo']?.toString() ?? '',
                  readOnly: true,
                  decoration: _decoracion(
                    'Correo electrónico (no editable)',
                    icono: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                _campo(_telefono, 'Teléfono', Icons.phone_outlined, max: 20),
                const SizedBox(height: 14),
                _campo(_direccion, 'Dirección', Icons.place_outlined, max: 255),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _navy),
                    onPressed: _guardando ? null : _guardarDatos,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar cambios',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _tarjeta(
          'Seguridad de la cuenta',
          Icons.shield_outlined,
          Form(
            key: _claveKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _campoClave(
                  _actual,
                  'Contraseña actual',
                  _ocultarActual,
                  () => setState(() => _ocultarActual = !_ocultarActual),
                  (v) => v == null || v.isEmpty
                      ? 'Ingresa tu contraseña actual'
                      : null,
                ),
                const SizedBox(height: 14),
                _campoClave(
                  _nueva,
                  'Nueva contraseña',
                  _ocultarNueva,
                  () => setState(() => _ocultarNueva = !_ocultarNueva),
                  (v) => v == null || v.length < 12 || v.length > 128
                      ? 'Debe tener entre 12 y 128 caracteres'
                      : v == _actual.text
                      ? 'Debe ser diferente de la actual'
                      : null,
                ),
                const SizedBox(height: 14),
                _campoClave(
                  _confirmacion,
                  'Confirmar nueva contraseña',
                  _ocultarConfirmacion,
                  () => setState(
                    () => _ocultarConfirmacion = !_ocultarConfirmacion,
                  ),
                  (v) =>
                      v != _nueva.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _navy),
                    onPressed: _claveCargando ? null : _cambiarClave,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      _claveCargando ? 'Actualizando...' : 'Cambiar contraseña',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
