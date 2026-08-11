// Minimal static file server for the release web build, with an explicit MIME
// map so .js/.wasm are always served with the correct Content-Type.
import 'dart:io';

const root = r'C:\FrontEndPart\build\web';

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
};

String extOf(String p) {
  final i = p.lastIndexOf('.');
  return i < 0 ? '' : p.substring(i).toLowerCase();
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8090);
  stdout.writeln('serving $root at http://127.0.0.1:8090');
  await for (final req in server) {
    try {
      var path = Uri.decodeComponent(req.uri.path);
      if (path == '/' || path.isEmpty) path = '/index.html';
      var file = File(root + path.replaceAll('/', Platform.pathSeparator));

      if (!await file.exists()) {
        // No file with an extension -> treat as a client route -> index.html.
        // A missing asset (has extension) -> 404.
        if (extOf(path).isNotEmpty) {
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
          continue;
        }
        file = File('$root${Platform.pathSeparator}index.html');
      }

      final ct = mime[extOf(file.path)] ?? 'application/octet-stream';
      req.response.headers.set(HttpHeaders.contentTypeHeader, ct);
      req.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      await req.response.addStream(file.openRead());
      await req.response.close();
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }
}
