import 'package:flutter/material.dart';
import '../validaciones/validaciones_wao.dart';
import '../Services/Usuarios.dart';
import 'HomeWeb.dart';
import 'RegistroWeb.dart';
import 'RecuperarWeb.dart';

const _navy = Color(0xFF102C54);
const _blue = Color(0xFF2463A5);
const _orange = Color(0xFFF5A623);
const _background = Color(0xFFF5F8FC);

/// Login exclusivo para Flutter Web. Mantiene el servicio de autenticación.
class LoginWeb extends StatefulWidget {
  const LoginWeb({super.key});
  @override
  State<LoginWeb> createState() => _LoginWebState();
}

class _LoginWebState extends State<LoginWeb> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _api = ApiUsuario();
  bool _loading = false;
  bool _hidePassword = true;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await _api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      if (result != null && result['usuario'] != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (homeContext) => HomeWeb(
              usuario: Map<String, dynamic>.from(result['usuario'] as Map),
              onLogout: () {
                Navigator.of(homeContext).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginWeb()),
                  (_) => false,
                );
              },
            ),
          ),
        );
      } else {
        _showMessage('Correo o contraseña incorrectos');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo iniciar sesión. Comprueba tu conexión.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB83E4B),
      ),
    );
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF63758D)),
      prefixIcon: Icon(icon, color: _blue, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E1ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.7),
      ),
    );
  }

  Widget _brandPanel({required bool compact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 54,
        vertical: compact ? 28 : 52,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/Login.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(Color(0x99102C54), BlendMode.darken),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo y eslogan juntos, sin espacios excesivos.
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
          SizedBox(height: compact ? 4 : 8),
          Text(
            'Descubre. Vive. Planifica.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 24 : 36,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Explora destinos, encuentra negocios turísticos y organiza tu próxima aventura en un solo lugar.',
            style: TextStyle(
              color: Color(0xFFE1EBF7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 42),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _BrandChip(icon: Icons.explore_outlined, label: 'Explora'),
                _BrandChip(icon: Icons.place_outlined, label: 'Descubre'),
                _BrandChip(
                  icon: Icons.calendar_month_outlined,
                  label: 'Organiza',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loginPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FlightBackgroundPainter()),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Inicio de sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _navy,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bienvenido de nuevo a WAO',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF65758C), fontSize: 15),
                    ),

                    const SizedBox(height: 34),
                    TextFormField(
                      controller: _email,
                      maxLength: 254,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(
                        'Correo electrónico',
                        Icons.mail_outline_rounded,
                      ),
                      validator: ValidacionesWao.correo,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _password,
                      maxLength: 128,
                      autocorrect: false,
                      enableSuggestions: false,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      decoration: _decoration(
                        'Contraseña',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          tooltip: _hidePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _blue,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa tu contraseña'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            _open(const PantallaOlvideContrasenaWeb()),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: _navy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _navy,
                                ),
                              )
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFDCE4EE)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '¿Aún no tienes cuenta?',
                            style: TextStyle(
                              color: Color(0xFF7A8799),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFDCE4EE)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _open(const RegistroWeb()),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Crear una cuenta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: const BorderSide(color: _blue),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                Expanded(flex: 6, child: _loginPanel()),
              ],
            );
          }
          return Column(
            children: [
              _brandPanel(compact: true),
              Expanded(child: _loginPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BrandChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _orange, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Decoración sutil de aviones y rutas, detrás del formulario.
class _FlightBackgroundPainter extends CustomPainter {
  const _FlightBackgroundPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF2463A5).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-30, size.height * .23)
      ..cubicTo(
        size.width * .22,
        size.height * .04,
        size.width * .35,
        size.height * .51,
        size.width * .71,
        size.height * .21,
      )
      ..cubicTo(
        size.width * .95,
        size.height * .04,
        size.width * 1.10,
        size.height * .28,
        size.width * .90,
        size.height * .43,
      );
    _drawDashed(canvas, path, ink);
    final second = Path()
      ..moveTo(size.width * .06, size.height * .87)
      ..cubicTo(
        size.width * .44,
        size.height * .57,
        size.width * .46,
        size.height * 1.12,
        size.width * 1.05,
        size.height * .74,
      );
    _drawDashed(canvas, second, ink);
    _plane(canvas, Offset(size.width * .80, size.height * .12), 54, -.42);
    _plane(canvas, Offset(size.width * .16, size.height * .78), 39, .72);
    _plane(canvas, Offset(size.width * .93, size.height * .88), 33, -.85);
    // Iconos turísticos distribuidos en los márgenes del panel.
    // El área central permanece libre para el formulario.
    _travelIcon(
      canvas,
      Icons.explore_rounded,
      Offset(size.width * .91, size.height * .42),
      66,
      .31,
    );
    _travelIcon(
      canvas,
      Icons.luggage_rounded,
      Offset(size.width * .90, size.height * .77),
      76,
      .30,
    );
    _travelIcon(
      canvas,
      Icons.confirmation_number_outlined,
      Offset(size.width * .13, size.height * .62),
      62,
      .25,
      angle: -.25,
    );
    _travelIcon(
      canvas,
      Icons.place_rounded,
      Offset(size.width * .11, size.height * .15),
      37,
      .32,
    );
    _travelIcon(
      canvas,
      Icons.map_outlined,
      Offset(size.width * .83, size.height * .20),
      46,
      .22,
      angle: .18,
    );
    _travelIcon(
      canvas,
      Icons.beach_access_rounded,
      Offset(size.width * .12, size.height * .93),
      54,
      .22,
    );
    _travelIcon(
      canvas,
      Icons.public_rounded,
      Offset(size.width * .89, size.height * .96),
      45,
      .22,
    );
    _travelIcon(
      canvas,
      Icons.flight_takeoff_rounded,
      Offset(size.width * .48, size.height * .06),
      43,
      .24,
    );
    final marker = Paint()..color = const Color(0xFF2463A5).withOpacity(.23);
    for (final point in [
      Offset(size.width * .10, size.height * .28),
      Offset(size.width * .89, size.height * .56),
    ]) {
      canvas.drawCircle(point, 11, marker);
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
    }
  }

  void _travelIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    double opacity, {
    double angle = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: const Color(0xFF2463A5).withOpacity(opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 9), paint);
        distance += 18;
      }
    }
  }

  void _plane(Canvas canvas, Offset center, double size, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.scale(size / 100);
    final paint = Paint()
      ..color = const Color(0xFF2463A5).withOpacity(.27)
      ..style = PaintingStyle.fill;
    final plane = Path()
      ..moveTo(0, -48)
      ..quadraticBezierTo(7, -47, 9, -33)
      ..lineTo(12, -10)
      ..lineTo(44, 11)
      ..quadraticBezierTo(49, 15, 47, 23)
      ..lineTo(10, 13)
      ..lineTo(7, 33)
      ..lineTo(22, 43)
      ..lineTo(22, 48)
      ..lineTo(0, 43)
      ..lineTo(-22, 48)
      ..lineTo(-22, 43)
      ..lineTo(-7, 33)
      ..lineTo(-10, 13)
      ..lineTo(-47, 23)
      ..quadraticBezierTo(-49, 15, -44, 11)
      ..lineTo(-12, -10)
      ..lineTo(-9, -33)
      ..quadraticBezierTo(-7, -47, 0, -48)
      ..close();
    canvas.drawPath(plane, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlightBackgroundPainter oldDelegate) => false;
}
