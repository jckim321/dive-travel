import 'dart:convert';

import 'package:dive_travel_app/core/models/dive_star_assessment.dart';

class DiveStarFormImportException implements Exception {
  DiveStarFormImportException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parses and validates pasted Dive Star form JSON (v2 shape).
abstract final class DiveStarFormImport {
  static DiveStarForm parseAndValidate(String rawJson) {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      throw DiveStarFormImportException('empty');
    }
    late final Object decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      throw DiveStarFormImportException('invalid_json');
    }
    if (decoded is! Map) {
      throw DiveStarFormImportException('not_object');
    }
    final map = Map<String, dynamic>.from(decoded);
    final version = (map['version'] as String? ?? '').trim();
    if (version.isEmpty) {
      throw DiveStarFormImportException('missing_version');
    }

    // Force draft on import (phase 1: never activate from paste).
    map['status'] = 'draft';
    map['active'] = false;

    final form = DiveStarForm.fromDocument(version, map);
    _validateStructure(form);
    return form;
  }

  static void _validateStructure(DiveStarForm form) {
    if (form.areas.isEmpty) {
      throw DiveStarFormImportException('no_areas');
    }
    final areaIds = <String>{};
    var areaSum = 0;
    for (final area in form.areas) {
      if (area.id.isEmpty) {
        throw DiveStarFormImportException('empty_area_id');
      }
      if (!areaIds.add(area.id)) {
        throw DiveStarFormImportException('duplicate_area:${area.id}');
      }
      areaSum += area.maxPoints;
    }
    if (areaSum != 100) {
      throw DiveStarFormImportException('area_sum_$areaSum');
    }

    final gateIds = <String>{};
    for (final gate in form.gates) {
      if (gate.id.isEmpty) {
        throw DiveStarFormImportException('empty_gate_id');
      }
      if (!gateIds.add(gate.id)) {
        throw DiveStarFormImportException('duplicate_gate:${gate.id}');
      }
    }

    final itemIds = <String>{};
    final itemSumByArea = <String, int>{};
    for (final item in form.items) {
      if (item.id.isEmpty) {
        throw DiveStarFormImportException('empty_item_id');
      }
      if (!itemIds.add(item.id)) {
        throw DiveStarFormImportException('duplicate_item:${item.id}');
      }
      if (!areaIds.contains(item.areaId)) {
        throw DiveStarFormImportException('item_area_unknown:${item.areaId}');
      }
      itemSumByArea[item.areaId] =
          (itemSumByArea[item.areaId] ?? 0) + item.maxPoints;
    }

    if (form.items.isNotEmpty) {
      for (final area in form.areas) {
        final sum = itemSumByArea[area.id] ?? 0;
        if (sum != area.maxPoints) {
          throw DiveStarFormImportException(
            'item_sum_${area.id}_${sum}_need_${area.maxPoints}',
          );
        }
      }
    }
  }
}
