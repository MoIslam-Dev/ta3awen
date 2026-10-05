import 'package:flutter/material.dart';
import '../data/algeria_data.dart';
import '../l10n/ext.dart';

class WilayaCommuneFields extends StatelessWidget {
  final String? wilaya;
  final String? commune;
  final ValueChanged<String?> onWilaya;
  final ValueChanged<String?> onCommune;
  final String wilayaLabel;
  final String communeLabel;

  const WilayaCommuneFields({
    super.key,
    required this.wilaya,
    required this.commune,
    required this.onWilaya,
    required this.onCommune,
    required this.wilayaLabel,
    required this.communeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final communes =
        wilaya == null ? const <String>[] : AlgeriaData.communesOf(wilaya!);
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: wilaya,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: wilayaLabel,
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            items: AlgeriaData.wilayas
                .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                .toList(),
            onChanged: onWilaya,
            validator: (v) => (v == null || v.isEmpty) ? l.wilayaInvalid : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: commune,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: communeLabel,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            items: communes
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: wilaya == null ? null : onCommune,
            validator: (v) => (v == null || v.isEmpty) ? l.communeInvalid : null,
          ),
        ),
      ],
    );
  }
}
