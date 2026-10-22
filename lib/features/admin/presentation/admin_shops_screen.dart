import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/admin_models.dart';
import 'package:dive_travel_app/core/models/dive_shop.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_assessment_screen.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/features/explore/presentation/resort_desk_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminShopsScreen extends StatelessWidget {
  const AdminShopsScreen({
    super.key,
    this.embedded = false,
    this.onOpenProducts,
  });

  final bool embedded;
  final ValueChanged<String>? onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final shops = store.shops;
        final plaque = store.plaqueQueue;

        return adminScreenShell(
          embedded: embedded,
          title: l10n.adminShopsTitle,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                l10n.adminPartnersGradeHint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: embedded ? AdminConsoleTheme.muted : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.adminPlaqueQueue,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (plaque.isEmpty)
                Card(child: ListTile(title: Text(l10n.adminPlaqueEmpty)))
              else
                for (final stats in plaque) ...[
                  _PlaqueTile(
                    shop: DiveShopCatalog.byId(stats.shopId),
                    shopId: stats.shopId,
                    stars: stats.diveStar,
                    rating: stats.avgOverall,
                    reviewCount: stats.reviewCount,
                    status: stats.plaqueStatus,
                    internalScore: stats.internalScore,
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 16),
              Text(
                l10n.adminShopMonitor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final shop in shops) ...[
                _ShopMonitorTile(
                  shop: shop,
                  live: store.liveStatsFor(shop.hullId) ??
                      store.liveStatsFor(shop.id),
                  onOpenProducts: onOpenProducts,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlaqueTile extends StatelessWidget {
  const _PlaqueTile({
    required this.shop,
    required this.shopId,
    required this.stars,
    required this.rating,
    required this.reviewCount,
    required this.status,
    required this.internalScore,
  });

  final DiveShop? shop;
  final String shopId;
  final int stars;
  final double rating;
  final int reviewCount;
  final PlaqueStatus status;
  final int internalScore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final name = shop?.name ?? shopId;
    final statusLabel = switch (status) {
      PlaqueStatus.queued => l10n.adminPlaqueQueued,
      PlaqueStatus.shipped => l10n.adminPlaqueShipped,
      PlaqueStatus.none => l10n.adminPlaqueNone,
    };

    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium),
        title: Text(name),
        subtitle: Text(
          '${l10n.exploreDiveStar(stars)} · '
          '${l10n.homeDiveStarSubtitle(rating.toStringAsFixed(1), reviewCount)}\n'
          '${l10n.adminInternalScore} $internalScore · $statusLabel',
        ),
        isThreeLine: true,
        trailing: status == PlaqueStatus.shipped
            ? const Icon(Icons.check_circle_outline, color: Color(0xFFC4A35A))
            : FilledButton(
                onPressed: () {
                  store.setPlaqueStatus(
                    shopId: shopId,
                    status: status == PlaqueStatus.queued
                        ? PlaqueStatus.shipped
                        : PlaqueStatus.queued,
                  );
                },
                child: Text(
                  status == PlaqueStatus.queued
                      ? l10n.adminPlaqueMarkShipped
                      : l10n.adminPlaqueRequest,
                ),
              ),
      ),
    );
  }
}

class _ShopMonitorTile extends StatelessWidget {
  const _ShopMonitorTile({
    required this.shop,
    required this.live,
    this.onOpenProducts,
  });

  final DiveShop shop;
  final ShopLiveStats? live;
  final ValueChanged<String>? onOpenProducts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final internalScore = live?.internalScore ?? 0;
    final reviewed = live?.diveStarReviewedAt;
    final expires = live?.diveStarExpiresAt;
    final dateFmt = DateFormat.yMMMd();
    final gradeLine = shop.stars > 0
        ? l10n.exploreDiveStar(shop.stars)
        : l10n.exploreStarPending;
    final datesLine = [
      if (reviewed != null)
        '${l10n.adminDiveStarReviewedAt} ${dateFmt.format(reviewed.toLocal())}',
      if (expires != null)
        '${l10n.adminDiveStarExpiresAt} ${dateFmt.format(expires.toLocal())}',
      if (shop.isDiveStarExpired) l10n.exploreDiveStarRenewalNeeded,
    ].join(' · ');

    return Card(
      child: ListTile(
        title: Text(shop.name),
        subtitle: Text(
          [
            shop.location,
            gradeLine,
            if (shop.reviewCount > 0)
              l10n.homeDiveStarSubtitle(
                shop.rating.toStringAsFixed(1),
                shop.reviewCount,
              ),
            '${l10n.adminInternalScore} $internalScore',
            if (datesLine.isNotEmpty) datesLine,
          ].join(' · '),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'products') {
              onOpenProducts?.call(shop.hullId);
              return;
            }
            if (value == 'desk') {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResortDeskScreen(shopId: shop.hullId),
                ),
              );
              return;
            }
            if (value == 'score') {
              await _editInternalScore(context, shop.hullId, internalScore);
              return;
            }
            if (value == 'dive_star') {
              await _editDiveStarGrade(
                context,
                shopId: shop.hullId,
                currentGrade: shop.stars,
                reviewedAt: reviewed,
                expiresAt: expires,
              );
              return;
            }
            if (value == 'dive_star_assess') {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminDiveStarAssessmentScreen(
                    shopId: shop.hullId,
                    shopName: shop.name,
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'products',
              child: Text(l10n.adminViewShopProducts),
            ),
            PopupMenuItem(
              value: 'dive_star_assess',
              child: Text(l10n.adminDiveStarAssessmentMenu),
            ),
            PopupMenuItem(
              value: 'dive_star',
              child: Text(l10n.adminDiveStarGradeEdit),
            ),
            PopupMenuItem(
              value: 'score',
              child: Text(l10n.adminInternalScoreEdit),
            ),
            PopupMenuItem(
              value: 'desk',
              child: Text(l10n.exploreEditResort),
            ),
          ],
        ),
        onTap: onOpenProducts == null
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ResortDeskScreen(shopId: shop.hullId),
                ),
              )
            : () => onOpenProducts!(shop.hullId),
      ),
    );
  }
}

Future<void> _editInternalScore(
  BuildContext context,
  String shopId,
  int current,
) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  final controller = TextEditingController(text: current > 0 ? '$current' : '');
  final score = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.adminInternalScoreEdit),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.adminInternalScore,
            hintText: l10n.adminInternalScoreHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            onPressed: () {
              final raw = int.tryParse(controller.text.trim()) ?? 0;
              Navigator.pop(context, raw.clamp(0, 100));
            },
            child: Text(l10n.briefSave),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (score == null || !context.mounted) {
    return;
  }
  await store.setInternalScore(shopId: shopId, score: score);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminInternalScoreSaved)),
    );
  }
}

Future<void> _editDiveStarGrade(
  BuildContext context, {
  required String shopId,
  required int currentGrade,
  DateTime? reviewedAt,
  DateTime? expiresAt,
}) async {
  final l10n = AppLocalizations.of(context);
  final store = DiverStoreScope.of(context);
  var grade = currentGrade.clamp(0, 3);
  var reviewed = reviewedAt ?? DateTime.now();
  var expires =
      expiresAt ?? DateTime.now().add(const Duration(days: 365));

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final dateFmt = DateFormat.yMMMd();
          return AlertDialog(
            title: Text(l10n.adminDiveStarGradeEdit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: grade,
                    decoration: InputDecoration(
                      labelText: l10n.adminDiveStarGrade,
                      helperText: l10n.adminDiveStarGradeHint,
                    ),
                    items: [
                      for (var i = 0; i <= 3; i++)
                        DropdownMenuItem(value: i, child: Text('$i')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => grade = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDiveStarReviewedAt),
                    subtitle: Text(dateFmt.format(reviewed.toLocal())),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: reviewed.toLocal(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => reviewed = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDiveStarExpiresAt),
                    subtitle: Text(dateFmt.format(expires.toLocal())),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expires.toLocal(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() => expires = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.adminHqClose),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.briefSave),
              ),
            ],
          );
        },
      );
    },
  );
  if (saved != true || !context.mounted) {
    return;
  }
  await store.setDiveStarGrade(
    shopId: shopId,
    grade: grade,
    reviewedAt: reviewed,
    expiresAt: expires,
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminDiveStarGradeSaved)),
    );
  }
}
