import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Services/Usuarios.dart';
import 'VerificarCorreoWeb.dart';

const Color waoOrange = Color(0xFFF5A623);
const Color waoNavy = Color(0xFF102C54);
const Color waoBlue = Color(0xFF2463A5);
const Color waoBackground = Color(0xFFF5F8FC);
const _orange = Color(0xFFF5A623);

class RegistroWeb extends StatefulWidget {
  const RegistroWeb({super.key});

  @override
  State<RegistroWeb> createState() => _RegistroWebState();
}

class _RegistroWebState extends State<RegistroWeb> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  final ApiUsuario _api = ApiUsuario();

  int _rol = 3; // 3: Turista, 2: Propietario
  bool _acepta = false;
  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;
  String? _errorCorreoServidor;

  @override
  void dispose() {
    for (final controller in [
      _nombre,
      _apellido,
      _correo,
      _telefono,
      _direccion,
      _password,
      _confirmacion,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _mensaje(String mensaje, {bool exito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: exito ? const Color(0xFF287B57) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _registrar() async {
    if (_cargando) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_acepta) {
      _mensaje('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() {
      _cargando = true;
      _errorCorreoServidor = null;
    });

    try {
      // Solo una solicitud al servidor por intento de registro.
      final resultado = await _api.registrarUsuarioDetallado(
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        correo: _correo.text.trim().toLowerCase(),
        telefono: _telefono.text.trim(),
        direccion: _direccion.text.trim(),
        password: _password.text,
        idRol: _rol,
      );

      if (!mounted) return;

      if (resultado['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                VerificarCorreoWeb(correo: _correo.text.trim().toLowerCase()),
          ),
        );
      } else if (resultado['statusCode'] == 409) {
        setState(() {
          _errorCorreoServidor = 'Este correo ya está registrado';
        });
        _formKey.currentState?.validate();
        _mensaje('Ya existe una cuenta con ese correo electrónico');
      } else {
        _mensaje(
          resultado['message']?.toString() ??
              'No se pudo completar el registro',
        );
      }
    } catch (e) {
      if (mounted) {
        _mensaje('Ocurrió un error inesperado al registrar la cuenta');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String? _requerido(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo requerido' : null;

  String? _validarCorreo(String? value) {
    final correo = (value ?? '').trim().toLowerCase();

    if (correo.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    if (correo.length > 150) {
      return 'El correo no puede superar los 150 caracteres';
    }

    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@(gmail\.com|hotmail\.com)$');

    if (!regex.hasMatch(correo)) {
      return 'Solo se permiten correos Gmail o Hotmail';
    }

    return null;
  }

  String? _validarTelefono(String? value) {
    final telefono = value?.trim() ?? '';
    if (telefono.isEmpty) return 'Ingresa tu teléfono';
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(telefono)) {
      return 'Debe tener 10 dígitos y comenzar con 0';
    }
    return null;
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF63758D)),
      prefixIcon: Icon(icon, color: waoBlue, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: waoBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E1ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: waoBlue, width: 1.7),
      ),
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController controller,
    IconData icon, {
    TextInputType? teclado,
    bool oculto = false,
    VoidCallback? cambiarVisibilidad,
    String? Function(String?)? validar,
    Iterable<String>? autofill,
    List<TextInputFormatter>? formatos,
    ValueChanged<String>? alCambiar,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      obscureText: oculto,
      autofillHints: autofill,
      inputFormatters: formatos,
      onChanged: alCambiar,
      validator: validar ?? _requerido,
      decoration: _decoration(
        etiqueta,
        icon,
        suffix: cambiarVisibilidad == null
            ? null
            : IconButton(
                tooltip: oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: cambiarVisibilidad,
                icon: Icon(
                  oculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: waoBlue,
                ),
              ),
      ),
    );
  }

  Widget _fila(bool ancho, Widget a, Widget b) {
    if (!ancho) return Column(children: [a, const SizedBox(height: 16), b]);
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  String? _validarDireccion(String? value) {
    final direccion = value?.trim() ?? '';

    if (direccion.isEmpty) {
      return 'Ingresa tu dirección';
    }

    if (direccion.length < 10) {
      return 'La dirección debe tener al menos 10 caracteres';
    }

    if (direccion.length > 150) {
      return 'La dirección no puede superar los 150 caracteres';
    }

    if (!RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ]').hasMatch(direccion)) {
      return 'Ingresa una dirección válida';
    }

    return null;
  }

  Widget _selectorRol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de cuenta',
          style: TextStyle(color: waoNavy, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final item in [
              (3, 'Turista', Icons.person_outline),
              (2, 'Propietario', Icons.storefront_outlined),
            ])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: item.$1 == 3 ? 10 : 0),
                  child: InkWell(
                    onTap: _cargando
                        ? null
                        : () => setState(() => _rol = item.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _rol == item.$1
                            ? waoOrange.withOpacity(.13)
                            : waoBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _rol == item.$1
                              ? waoOrange
                              : const Color(0xFFD8E1ED),
                          width: _rol == item.$1 ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.$3,
                            size: 18,
                            color: _rol == item.$1 ? waoNavy : waoBlue,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              item.$2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: waoNavy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _brandPanel({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 48,
        vertical: compact ? 25 : 52,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('Registrar.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(Color(0x99102C54), BlendMode.darken),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icon/Logo2.png',
                width: compact ? 190 : 260,
                height: compact ? 70 : 92,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (context, error, stackTrace) => Text(
                  'WAO',
                  style: TextStyle(
                    color: _orange,
                    fontSize: compact ? 34 : 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            'Tu próxima aventura comienza aquí.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 23 : 34,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Únete a WAO para descubrir destinos, explorar negocios turísticos y organizar experiencias inolvidables.',
            style: TextStyle(
              color: Color(0xFFE1EBF7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 42),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _brandChip(Icons.explore_outlined, 'Explora'),
                _brandChip(Icons.place_outlined, 'Descubre'),
                _brandChip(Icons.calendar_month_outlined, 'Organiza'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _brandChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.12),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: waoOrange, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    ),
  );

  Widget _registroPanel(bool wide) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Volver a iniciar sesión'),
                    style: TextButton.styleFrom(foregroundColor: waoBlue),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    color: waoNavy,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para unirte a WAO',
                  style: TextStyle(color: Color(0xFF65758C), fontSize: 15),
                ),
                const SizedBox(height: 28),
                _fila(
                  wide,
                  _campo(
                    'Nombre',
                    _nombre,
                    Icons.person_outline,
                    autofill: [AutofillHints.givenName],
                  ),
                  _campo(
                    'Apellido',
                    _apellido,
                    Icons.badge_outlined,
                    autofill: [AutofillHints.familyName],
                  ),
                ),
                const SizedBox(height: 16),
                _fila(
                  wide,
                  _campo(
                    'Correo electrónico',
                    _correo,
                    Icons.email_outlined,
                    teclado: TextInputType.emailAddress,
                    autofill: [AutofillHints.email],
                    validar: _validarCorreo,
                    alCambiar: (_) {
                      if (_errorCorreoServidor != null) {
                        setState(() => _errorCorreoServidor = null);
                      }
                    },
                  ),
                  _campo(
                    'Teléfono',
                    _telefono,
                    Icons.phone_outlined,
                    teclado: TextInputType.phone,
                    autofill: [AutofillHints.telephoneNumber],
                    formatos: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validar: _validarTelefono,
                  ),
                ),
                const SizedBox(height: 16),
                _fila(
                  wide,
                  _campo(
                    'Dirección',
                    _direccion,
                    Icons.location_on_outlined,
                    autofill: [AutofillHints.streetAddressLine1],
                    validar: _validarDireccion,
                    formatos: [LengthLimitingTextInputFormatter(150)],
                  ),
                  _selectorRol(),
                ),
                const SizedBox(height: 16),
                _fila(
                  wide,
                  _campo(
                    'Contraseña',
                    _password,
                    Icons.lock_outline,
                    oculto: _ocultarPassword,
                    cambiarVisibilidad: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                    validar: (v) {
                      if (v == null || v.isEmpty)
                        return 'Ingresa una contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  _campo(
                    'Confirmar contraseña',
                    _confirmacion,
                    Icons.lock_outline,
                    oculto: _ocultarConfirmacion,
                    cambiarVisibilidad: () => setState(
                      () => _ocultarConfirmacion = !_ocultarConfirmacion,
                    ),
                    validar: (v) {
                      if (v == null || v.isEmpty)
                        return 'Confirma tu contraseña';
                      if (v != _password.text)
                        return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: _acepta,
                  onChanged: _cargando
                      ? null
                      : (v) => setState(() => _acepta = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: waoOrange,
                  checkColor: waoNavy,
                  title: const Text(
                    'Acepto los Términos y Condiciones y la Política de Privacidad',
                    style: TextStyle(color: Color(0xFF65758C), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: waoOrange,
                      foregroundColor: waoNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: waoNavy,
                            ),
                          )
                        : const Text(
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        color: waoBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          if (wide) {
            return Row(
              children: [
                Expanded(flex: 5, child: _brandPanel(compact: false)),
                Expanded(flex: 7, child: _registroPanel(true)),
              ],
            );
          }
          return Column(
            children: [
              _brandPanel(compact: true),
              Expanded(child: _registroPanel(false)),
            ],
          );
        },
      ),
    );
  }
}
