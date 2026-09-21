import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminInstructorsScreen extends StatelessWidget {
  const AdminInstructorsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final pending = store.pendingInstructors;

    return adminScreenShell(
      embedded: embedded,
      title: l10n.adminInstructorsTitle,
      body: pending.isEmpty
          ? Center(child: Text(l10n.adminNoPending))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: pending.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _InstructorCard(instructor: pending[index]);
              },
            ),
    );
  }
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.instructor});

  final PendingInstructor instructor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(instructor.displayName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(instructor.email, style: theme.textTheme.bodyMedium),
            if (instructor.agency.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                l10n.adminInstructorAgency(instructor.agency),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: instructor.photoUrl.isEmpty
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.badge_outlined, size: 48),
                        ),
                      )
                    : Image.network(
                        instructor.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => store.rejectInstructor(instructor.uid),
                    child: Text(l10n.adminReject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: Key('admin-approve-${instructor.uid}'),
                    onPressed: () => store.approveInstructor(instructor.uid),
                    child: Text(l10n.adminApprove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
