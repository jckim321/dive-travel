import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Natural Earth land GeoJSON → compact lon/lat rings for CustomPaint.
void main(List<String> args) {
  final input = File(args.first);
  final output = File(args[1]);
  final data = jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
  final features = data['features'] as List<dynamic>;
  final rings = <List<List<double>>>[];

  void addRing(List<dynamic> ring) {
    if (ring.length < 8) {
      return;
    }
    final simplified = <List<double>>[];
    double? lastLon;
    double? lastLat;
    for (final point in ring) {
      final coords = point as List<dynamic>;
      final lon = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      if (lastLon == null) {
        simplified.add([lon, lat]);
        lastLon = lon;
        lastLat = lat;
        continue;
      }
      final dx = lon - lastLon;
      final dy = lat - lastLat!;
      if (math.sqrt(dx * dx + dy * dy) < 1.15) {
        continue;
      }
      simplified.add([
        double.parse(lon.toStringAsFixed(2)),
        double.parse(lat.toStringAsFixed(2)),
      ]);
      lastLon = lon;
      lastLat = lat;
    }
    if (simplified.length >= 6) {
      rings.add(simplified);
    }
  }

  void walk(dynamic geometry) {
    if (geometry is! Map) {
      return;
    }
    final type = geometry['type'];
    final coords = geometry['coordinates'];
    if (type == 'Polygon') {
      addRing((coords as List)[0] as List);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords as List) {
        addRing((poly as List)[0] as List);
      }
    }
  }

  for (final feature in features) {
    walk((feature as Map)['geometry']);
  }

  final buffer = StringBuffer()
    ..writeln('/// Equirectangular land rings as [longitude, latitude].')
    ..writeln('/// Source: Natural Earth 110m land (public domain).')
    ..writeln('const worldLandRings = <List<List<double>>>[');
  for (final ring in rings) {
    buffer.write('  [');
    for (final p in ring) {
      buffer.write('[${p[0]},${p[1]}],');
    }
    buffer.writeln('],');
  }
  buffer.writeln('];');
  output.writeAsStringSync(buffer.toString());
  stdout.writeln('rings=${rings.length} bytes=${output.lengthSync()}');
}
