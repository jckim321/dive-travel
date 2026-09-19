import 'dart:io';

const _types = <String, String>{
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.map': 'application/json',
};

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8112 : int.parse(args.first);
  final root = Directory('build/web');
  if (!root.existsSync()) {
    stderr.writeln('build/web 이 없습니다. 먼저 flutter build web 을 실행하세요.');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final ips = await _lanIps();
  stdout.writeln('노트북:  http://127.0.0.1:$port');
  if (ips.isEmpty) {
    stdout.writeln('LAN IP를 찾지 못했습니다. Wi-Fi에 연결돼 있는지 확인하세요.');
  } else {
    for (final ip in ips) {
      stdout.writeln('휴대폰: http://$ip:$port');
    }
  }
  stdout.writeln('http 로 여세요. https 가 아닙니다.');
  stdout.writeln('Windows 방화벽이 막으면 tool/open_lan_firewall.ps1 을 관리자 권한으로 실행하세요.');

  await for (final request in server) {
    stdout.writeln(
      '${DateTime.now().toIso8601String()} ${request.method} ${request.uri.path} from ${request.connectionInfo?.remoteAddress.address}',
    );
    try {
      await _handle(request, root);
    } catch (error) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('$error');
      await request.response.close();
    }
  }
}

Future<void> _handle(HttpRequest request, Directory root) async {
  var rel = Uri.decodeComponent(request.uri.path);
  if (rel == '/' || rel.isEmpty) {
    rel = '/index.html';
  }
  var file = File('${root.path}$rel');
  if (!file.existsSync()) {
    final hasExtension = rel.split('/').last.contains('.');
    if (hasExtension) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.write('Not found');
      await request.response.close();
      return;
    }
    file = File('${root.path}/index.html');
  }
  final name = file.uri.pathSegments.isEmpty ? '' : file.uri.pathSegments.last;
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot);
  request.response.headers
    ..set(
      HttpHeaders.contentTypeHeader,
      _types[ext] ?? 'application/octet-stream',
    )
    ..set(HttpHeaders.cacheControlHeader, 'no-cache')
    ..set('Access-Control-Allow-Origin', '*');
  await request.response.addStream(file.openRead());
  await request.response.close();
}

Future<List<String>> _lanIps() async {
  final found = <String>[];
  for (final interface in await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLinkLocal: false,
  )) {
    for (final addr in interface.addresses) {
      if (addr.isLoopback || addr.isLinkLocal) {
        continue;
      }
      final ip = addr.address;
      if (ip.startsWith('169.254.')) {
        continue;
      }
      found.add(ip);
    }
  }
  found.sort(_wifiFirst);
  return found;
}

int _wifiFirst(String a, String b) {
  int score(String ip) {
    if (ip.startsWith('192.168.')) {
      return 0;
    }
    if (ip.startsWith('10.')) {
      return 1;
    }
    if (ip.startsWith('172.')) {
      return 2;
    }
    return 3;
  }

  return score(a).compareTo(score(b));
}
