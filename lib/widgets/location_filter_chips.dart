import 'package:flutter/material.dart';
import '../data/algeria_data.dart';
import '../l10n/ext.dart';

/// Wilaya + commune filter chips in the style of the listings feed.
///
/// Picking opens a bottom sheet with all wilayas (or the communes of the
/// currently selected wilaya); choosing a new wilaya clears the commune.
/// A `null` value means "all".
class LocationFilterChips extends StatelessWidget {
  final String? wilaya;
  final String? commune;
  final ValueChanged<String?> onWilayaChanged;
  final ValueChanged<String?> onCommuneChanged;

  const LocationFilterChips({
    super.key,
    required this.wilaya,
    required this.commune,
    required this.onWilayaChanged,
    required this.onCommuneChanged,
  });

  Future<void> _pickWilaya(BuildContext context) async {
    final l = context.l10n;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _option(
              ctx,
              title: l.allWilayas,
              icon: Icons.place_outlined,
              value: '__all__',
              selected: wilaya == null,
            ),
            for (final w in AlgeriaData.wilayas)
              _option(
                ctx,
                title: w,
                icon: Icons.place_outlined,
                value: w,
                selected: wilaya == w,
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    onWilayaChanged(selected == '__all__' ? null : selected);
  }

  Future<void> _pickCommune(BuildContext context) async {
    if (wilaya == null) return;
    final l = context.l10n;
    final communes = AlgeriaData.communesOf(wilaya!);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            _option(
              ctx,
              title: l.allCommunes,
              icon: Icons.location_city_outlined,
              value: '__all__',
              selected: commune == null,
            ),
            for (final c in communes)
              _option(
                ctx,
                title: c,
                icon: Icons.location_city_outlined,
                value: c,
                selected: commune == c,
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    onCommuneChanged(selected == '__all__' ? null : selected);
  }

  Widget _option(
    BuildContext ctx, {
    required String title,
    required IconData icon,
    required String value,
    required bool selected,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
          : null,
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: Icon(
        icon,
        size: 18,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          context,
          label: wilaya ?? l.filterWilaya,
          icon: Icons.place_outlined,
          selected: wilaya != null,
          onSelected: () => _pickWilaya(context),
        ),
        if (wilaya != null) ...[
          const SizedBox(width: 8),
          _chip(
            context,
            label: commune ?? l.filterCommune,
            icon: Icons.location_city_outlined,
            selected: commune != null,
            onSelected: () => _pickCommune(context),
          ),
        ],
      ],
    );
  }
}