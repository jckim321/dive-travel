import 'package:flutter/material.dart';

/// 탭 콘솔에 끼울 때는 AppBar 없이 body만, 단독 push일 때는 기존 Scaffold.
Widget adminScreenShell({
  required bool embedded,
  required String title,
  required Widget body,
}) {
  if (embedded) {
    return body;
  }
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: body,
  );
}
