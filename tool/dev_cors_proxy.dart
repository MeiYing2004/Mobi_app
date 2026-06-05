// Dev-only CORS proxy for Flutter Web on LAN. Bind 0.0.0.0 — not for production.
//
// dart run tool/dev_cors_proxy.dart [port]
import 'dart:async';
import 'dart:io';

const _defaultPort = 8765;

/// Longest-prefix route → upstream origin (Overpass = full interpreter URI).
final Map<String, Uri> _routes = {
  'nominatim': Uri.parse('https://nominatim.openstreetmap.org'),
  'osrm': Uri.parse('https://router.project-osrm.org'),
  'openmeteo': Uri.parse('https://api.open-meteo.com'),
  'carto/dark_all': Uri.parse('https://a.basemaps.cartocdn.com/dark_all'),
  'carto/voyager':
      Uri.parse('https://a.basemaps.cartocdn.com/rastertiles/voyager'),
  'opentopo': Uri.parse('https://a.tile.opentopomap.org'),
  'esri/world': Uri.parse(
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile',
  ),
  'overpass/kumi': Uri.parse('https://overpass.kumi.systems/api/interpreter'),
  'overpass/lz4': Uri.parse('https://lz4.overpass-api.de/api/interpreter'),
  'overpass/de': Uri.parse('https://overpass-api.de/api/interpreter'),
};

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? _defaultPort : _defaultPort;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('CORS proxy listening on http://0.0.0.0:$port (LAN + localhost)');
  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  _setCors(request.response, request.headers.value('origin'));

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  final routeKey = _matchRoute(request.uri.path);
  if (routeKey == null) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Unknown proxy route: ${request.uri.path}');
    await request.response.close();
    return;
  }

  final upstream = _buildUpstream(request.uri, routeKey);
  final client = HttpClient();
  try {
    late HttpClientRequest upstreamReq;
    switch (request.method) {
      case 'GET':
        upstreamReq = await client.getUrl(upstream);
        break;
      case 'POST':
        upstreamReq = await client.postUrl(upstream);
        break;
      default:
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
    }

    const forwardHeaders = {
      'user-agent',
      'accept',
      'accept-language',
      'content-type',
    };
    request.headers.forEach((name, values) {
      if (!forwardHeaders.contains(name.toLowerCase())) return;
      for (final v in values) {
        upstreamReq.headers.set(name, v);
      }
    });

    if (request.method == 'POST') {
      final body = await request.fold<List<int>>(
        <int>[],
        (prev, chunk) => prev..addAll(chunk),
      );
      upstreamReq.add(body);
    }

    final upstreamRes = await upstreamReq.close();
    request.response.statusCode = upstreamRes.statusCode;
    upstreamRes.headers.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == 'transfer-encoding' || lower == 'access-control-allow-origin') {
        return;
      }
      for (final v in values) {
        request.response.headers.add(name, v);
      }
    });
    _setCors(request.response, request.headers.value('origin'));
    await upstreamRes.pipe(request.response);
  } catch (e) {
    try {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Proxy error: $e');
      await request.response.close();
    } catch (_) {}
  } finally {
    client.close(force: true);
  }
}

String? _matchRoute(String path) {
  var normalized = path;
  if (normalized.startsWith('/')) normalized = normalized.substring(1);
  if (normalized.isEmpty) return null;

  String? best;
  for (final key in _routes.keys) {
    if (normalized == key || normalized.startsWith('$key/')) {
      if (best == null || key.length > best.length) best = key;
    }
  }
  return best;
}

Uri _buildUpstream(Uri requestUri, String routeKey) {
  final target = _routes[routeKey]!;
  final prefix = '/$routeKey';
  final path = requestUri.path;
  final remainder =
      path.length <= prefix.length ? '' : path.substring(prefix.length);

  if (remainder.isEmpty && routeKey.startsWith('overpass/')) {
    return target;
  }

  final mergedPath = '${target.path}$remainder';
  return target.replace(
    path: mergedPath,
    queryParameters:
        requestUri.queryParameters.isEmpty ? null : requestUri.queryParameters,
  );
}

void _setCors(HttpResponse response, String? origin) {
  final allowOrigin =
      (origin != null && origin.isNotEmpty) ? origin : '*';
  response.headers.set('Access-Control-Allow-Origin', allowOrigin);
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'Content-Type, Accept, User-Agent, Accept-Language',
  );
  response.headers.set('Access-Control-Max-Age', '86400');
}
