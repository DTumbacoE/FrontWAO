import 'package:flutter/material.dart';
import '../Services/Usuarios.dart';

class VerificarCorreoWeb extends StatefulWidget {
  final String correo;

  const VerificarCorreoWeb({super.key, required this.correo});

  @override
  State<VerificarCorreoWeb> createState() => _VerificarCorreoWebState();
}

class _VerificarCorreoWebState extends State<VerificarCorreoWeb> {
  final ApiUsuario _api = ApiUsuario();
  bool _enviando = false;

  Future<void> _reenviar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      final resultado = await _api.reenviarVerificacion(widget.correo);
      if (!mounted) return;
      final mensaje = resultado['message']?.toString() ??
          'No se pudo procesar la solicitud.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo solicitar el reenvío.')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined,
                    size: 76, color: Color(0xFF2463A5)),
                const SizedBox(height: 24),
                const Text('Verifica tu correo electrónico',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102C54),
                    )),
                const SizedBox(height: 16),
                const Text('Enviamos un enlace de confirmación a:',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(widget.correo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2463A5),
                    )),
                const SizedBox(height: 24),
                const Text(
                  'Revisa tu bandeja de entrada y la carpeta de spam. '
                  'Abre el enlace recibido para activar tu cuenta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _reenviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: const Color(0xFF102C54),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_enviando
                        ? 'Enviando...'
                        : 'Reenviar enlace de verificación'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _enviando
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
