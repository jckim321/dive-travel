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

/// Group code from an option name. First matching list wins.
/// Unmatched and blank names are [other], never the unset label.
String classifyOptionGroup(String name) {
  final text = name.trim().toLowerCase();
  const rules = <(String, List<String>)>[
    ('media', ['사진', '영상', '비디오', '포토', '카메라']),
    ('gear', ['장비', '렌탈', '대여', '슈트', '호흡기', 'bcd']),
    ('transfer', ['픽업', '샌딩', '공항', '셔틀', '차량', '트랜스퍼', '이동']),
    ('meal', ['식사', '점심', '저녁', '아침', '뷔페', '런치', '디너']),
    ('stay', ['숙박', '호텔', '객실', '룸', '펜션', '민박', '숙소']),
    (
      'activity',
      [
        '투어',
        '펀다이빙',
        '스노클',
        '다이빙',
        '보트',
        '체험',
        '액티비티',
        '골프',
        '스파',
        '마사지',
        '낚시',
        '요가',
      ],
    ),
  ];
  for (final rule in rules) {
    for (final word in rule.$2) {
      if (text.contains(word)) {
        return rule.$1;
      }
    }
  }
  return 'other';
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
