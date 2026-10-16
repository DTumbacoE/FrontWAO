class ValidacionesWao {
  static String? nombre(String? value, {String campo = 'Nombre'}) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa $campo';
    if (texto.length < 2 || texto.length > 60) {
      return '$campo debe tener entre 2 y 60 caracteres';
    }
    final patron = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$");
    if (!patron.hasMatch(texto)) {
      return 'Usa letras y separadores válidos, sin números ni símbolos';
    }
    return null;
  }

  static String? telefono(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu teléfono';
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(texto)) {
      return 'Debe comenzar por 0 y tener exactamente 10 dígitos';
    }
    return null;
  }

  static String? contrasenaNueva(String? value, String actual) {
    final clave = value ?? '';
    if (clave.length < 12 || clave.length > 128) {
      return 'Debe tener entre 12 y 128 caracteres';
    }
    if (clave.trim().isEmpty || clave != clave.trim()) {
      return 'No uses solo espacios ni espacios al inicio o final';
    }
    if (clave == actual) return 'Debe ser diferente de la actual';
    return null;
  }

  static String? correo(String? value) {
    final correo = (value ?? '').trim();
    if (correo.isEmpty) return 'Ingresa tu correo';
    if (correo.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'Correo electrónico inválido';
    }
    return null;
  }
}
