import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/data/session_controller.dart';

/// Temporary admin-only line for a signup profile write that customers do not see.
class ProfileWriteDebugFooter extends StatelessWidget {
  const ProfileWriteDebugFooter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final store = DiverStoreScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([session, store]),
      builder: (context, _) {
        final note = session.profileWriteNote;
        final show = note != null && note.isNotEmpty && store.stats.isAdmin;
        return Stack(
          children: [
            child,
            if (show)
              Positioned(
                left: 12,
                right: 12,
                bottom: 4,
                child: IgnorePointer(
                  child: Text(
                    note,
                    key: const Key('profile-write-debug'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8AA0B8)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
