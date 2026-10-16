import 'package:http/http.dart' as http;

import 'cliente_http_stub.dart'
    if (dart.library.js_interop) 'cliente_http_web.dart' as plataforma;

http.Client crearClienteHttp() => plataforma.crearClienteHttp();