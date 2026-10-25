/// Option groups. Edit this list when the owner changes the names.
class OptionGroup {
  const OptionGroup(this.id, this.nameKo);

  final String id;
  final String nameKo;
}

const List<OptionGroup> optionGroups = [
  OptionGroup('stay', '숙박'),
  OptionGroup('gear', '장비'),
  OptionGroup('media', '사진·영상'),
  OptionGroup('transfer', '픽업·이동'),
  OptionGroup('meal', '식사'),
  OptionGroup('activity', '액티비티·투어'),
  OptionGroup('other', '기타'),
];

/// Shown when an option has no group.
const String optionGroupUnsetLabel = '미분류';

/// Known code, or empty when missing or not in [optionGroups].
String normalizeOptionGroup(String? raw) {
  final code = raw?.trim() ?? '';
  for (final group in optionGroups) {
    if (group.id == code) {
      return code;
    }
  }
  return '';
}

String optionGroupNameKo(String code) {
  final normalized = normalizeOptionGroup(code);
  if (normalized.isEmpty) {
    return optionGroupUnsetLabel;
  }
  for (final group in optionGroups) {
    if (group.id == normalized) {
      return group.nameKo;
    }
  }
  return optionGroupUnsetLabel;
}
