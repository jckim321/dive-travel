import 'package:dive_travel_app/core/models/member_grade.dart';

/// Admin fill for an existing users doc. Only empty grade, email, and name.
Map<String, Object?> memberProfileRepairPatch({
  required bool gradeMissing,
  required String existingEmail,
  required String existingName,
  required String email,
  required String displayName,
  required String uid,
}) {
  final patch = <String, Object?>{};
  if (gradeMissing) {
    patch['member_grade'] = MemberGrade.silver.firestoreValue;
  }
  final nextEmail = email.trim();
  if (existingEmail.trim().isEmpty && nextEmail.isNotEmpty) {
    patch['email'] = nextEmail;
  }
  if (existingName.trim().isEmpty) {
    final name = displayName.trim();
    patch['display_name'] = name.isEmpty ? uid : name;
  }
  return patch;
}
