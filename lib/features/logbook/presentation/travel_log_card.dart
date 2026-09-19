import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class TravelLogCard extends StatelessWidget {
  const TravelLogCard({
    super.key,
    required this.log,
    required this.logNumber,
    required this.onReview,
    required this.onEdit,
  });

  final DiveLog log;
  final int logNumber;
  final VoidCallback onReview;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = log.profile;
    final date = DateFormat('yyyy.MM.dd HH:mm').format(log.divedAt);
    final mix = switch (profile?.mix ?? DiveMix.air) {
      DiveMix.air => l10n.logbookMixAir,
      DiveMix.nitrox32 => l10n.logbookMixNx32,
      DiveMix.nitrox36 => l10n.logbookMixNx36,
    };
    final sac = profile?.sacLitersPerMin;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8E1D4)),
            boxShadow: AppTheme.cardShadow,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.navy, AppTheme.ocean, AppTheme.gold],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.goldSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.gold),
                  ),
                  child: Text(
                    'LOG #$logNumber',
                    style: const TextStyle(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.siteName, style: theme.textTheme.titleSmall),
                      Text(date, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  key: const Key('log-edit'),
                  onPressed: onEdit,
                  child: Text(l10n.logbookEdit),
                ),
                TextButton(
                  key: const Key('log-review'),
                  onPressed: onReview,
                  child: Text(l10n.reviewWrite),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _briefSummary(l10n),
                style: const TextStyle(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _Metric(
                    label: l10n.logbookMaxDepth,
                    value: _m(profile.maxDepthM),
                  ),
                  _Metric(
                    label: l10n.logbookAvgDepth,
                    value: _m(profile.avgDepthM),
                  ),
                  _Metric(
                    label: l10n.logbookMinutes,
                    value: profile.minutes == null
                        ? '—'
                        : '${profile.minutes}${l10n.logbookMinUnit}',
                  ),
                  _Metric(
                    label: l10n.logbookSac,
                    value: sac == null ? '—' : '${sac.toStringAsFixed(1)}L',
                  ),
                ],
              ),
            ),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _Metric(label: l10n.logbookMix, value: mix),
                  _Metric(
                    label: l10n.logbookPressure,
                    value: profile.startBar == null
                        ? '—'
                        : '${profile.startBar}→${profile.endBar ?? '—'}',
                  ),
                  _Metric(
                    label: l10n.logbookTemp,
                    value: profile.tempC == null
                        ? '—'
                        : '${profile.tempC!.toStringAsFixed(0)}°C',
                  ),
                  Expanded(
                    child: _AirRemain(ratio: profile.remainingBarRatio),
                  ),
                ],
              ),
            ),
          if (log.photoUrl != null &&
              log.photoUrl!.isNotEmpty &&
              !log.photoUrl!.startsWith('memory://'))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  log.photoUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (log.memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(log.memo, style: theme.textTheme.bodyMedium),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppTheme.ocean),
                const SizedBox(width: 6),
                Text(
                  l10n.logbookSelfRegistered,
                  style: const TextStyle(
                    color: AppTheme.ocean,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  String _m(double? value) => value == null ? '—' : '${value.toStringAsFixed(0)}m';

  String _briefSummary(AppLocalizations l10n) {
    final profile = log.profile;
    if (profile == null) {
      return '${log.siteName} · ${l10n.logbookBriefEmpty} · ${l10n.logbookSelfRegistered}';
    }
    final mix = switch (profile.mix) {
      DiveMix.air => l10n.logbookMixAir,
      DiveMix.nitrox32 => l10n.logbookMixNx32,
      DiveMix.nitrox36 => l10n.logbookMixNx36,
    };
    final bits = <String>[log.siteName];
    if (profile.maxDepthM != null) {
      bits.add(_m(profile.maxDepthM));
    }
    if (profile.minutes != null) {
      bits.add('${profile.minutes}${l10n.logbookMinUnit}');
    }
    bits.add(mix);
    if (profile.startBar != null) {
      bits.add('${profile.startBar}→${profile.endBar ?? '—'}');
    }
    if (log.memo.isNotEmpty) {
      final memo = log.memo.length > 22
          ? '${log.memo.substring(0, 22)}…'
          : log.memo;
      bits.add(memo);
    }
    return bits.join(' · ');
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _AirRemain extends StatelessWidget {
  const _AirRemain({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.logbookAirLeft,
          style: const TextStyle(fontSize: 10, color: AppTheme.muted),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EBEE),
            color: ratio < 0.25 ? const Color(0xFFC4A35A) : AppTheme.ocean,
          ),
        ),
      ],
    );
  }
}
