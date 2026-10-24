import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Maps legacy workbench section index (0..4) to wizard step (0..2).
int briefStepForSection(int sectionIndex) {
  return switch (sectionIndex) {
    0 || 1 || 2 => 0,
    3 => 1,
    _ => 2,
  };
}

/// Three-step progress strip for the product registration workbench.
class ProductBriefStepper extends StatelessWidget {
  const ProductBriefStepper({
    super.key,
    required this.stepIndex,
    required this.onStepTap,
    this.enabled = true,
  });

  /// 0 = basics, 1 = price/options, 2 = review/submit.
  final int stepIndex;
  final ValueChanged<int> onStepTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.briefStepBasics,
      l10n.briefStepPricing,
      l10n.briefStepReview,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: i <= stepIndex
                      ? AppTheme.navy
                      : const Color(0xFFD0D5DD),
                ),
              ),
            _StepChip(
              index: i,
              label: labels[i],
              selected: i == stepIndex,
              done: i < stepIndex,
              onTap: enabled ? () => onStepTap(i) : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.selected,
    required this.done,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected || done ? AppTheme.navy : Colors.white;
    final fg = selected || done ? Colors.white : AppTheme.muted;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('brief-step-$index'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
