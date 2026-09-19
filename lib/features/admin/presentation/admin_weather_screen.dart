import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/constants/app_constants.dart';
import 'package:dive_travel_app/core/data/dive_shop_catalog.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AdminWeatherScreen extends StatefulWidget {
  const AdminWeatherScreen({super.key});

  @override
  State<AdminWeatherScreen> createState() => _AdminWeatherScreenState();
}

class _AdminWeatherScreenState extends State<AdminWeatherScreen> {
  String _shopId = AppConstants.defaultPartnerShopId;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weatherAdminTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.weatherAdminBody),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('weather-shop'),
            initialValue: _shopId,
            items: [
              for (final shop in DiveShopCatalog.shops)
                DropdownMenuItem(value: shop.id, child: Text(shop.name)),
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
            onPressed: () async {
              await store.cancelBookingsForWeather(
                shopId: _shopId,
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
      ),
    );
  }
}
