import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/data/dive_star.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_screen_shell.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminWeatherScreen extends StatefulWidget {
  const AdminWeatherScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminWeatherScreen> createState() => _AdminWeatherScreenState();
}

class _AdminWeatherScreenState extends State<AdminWeatherScreen> {
  String? _shopId;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return adminScreenShell(
      embedded: widget.embedded,
      title: l10n.weatherAdminTitle,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final shops = store.shopStats;
          final selected = shops.any((shop) => shop.shopId == _shopId)
              ? _shopId
              : null;
          return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.weatherAdminBody),
          const SizedBox(height: 16),
          if (shops.isEmpty)
            Text(
              l10n.shopPickerEmpty,
              key: const Key('weather-shop-empty'),
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('weather-shop'),
              initialValue: selected,
              items: [
                for (final shop in shops)
                  DropdownMenuItem(
                    value: shop.shopId,
                    child: Text(_weatherShopLabel(shop)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _shopId = value);
                }
              },
              decoration: InputDecoration(labelText: l10n.partnerShopName),
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.weatherTourDate),
            subtitle: Text('${_date.year}.${_date.month}.${_date.day}'),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (picked != null) {
                setState(() => _date = picked);
              }
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('weather-cancel-submit'),
            onPressed: selected == null
                ? null
                : () async {
              await store.cancelBookingsForWeather(
                shopId: selected,
                tourDate: _date,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.weatherCancelDone)),
                );
              }
            },
            icon: const Icon(Icons.thunderstorm_outlined),
            label: Text(l10n.weatherCancel),
          ),
        ],
      );
        },
      ),
    );
  }
}

String _weatherShopLabel(ShopLiveStats stats) {
  final name = stats.name?.trim() ?? '';
  return name.isEmpty ? stats.shopId : name;
}
