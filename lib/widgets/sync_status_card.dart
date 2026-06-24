import 'package:flutter/material.dart';

class SyncStatusCard extends StatelessWidget {
  final String? lastSyncAt;
  final int importedCategories;
  final int importedProducts;

  const SyncStatusCard({
    super.key,
    this.lastSyncAt,
    required this.importedCategories,
    required this.importedProducts,
  });

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Nunca';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} $hour:$minute';
    } catch (_) {
      return 'Nunca';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Estado de sincronización',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.schedule,
              'Última sincronización',
              _formatDate(lastSyncAt),
              theme,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.category_rounded,
              'Categorías importadas',
              '$importedCategories',
              theme,
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.inventory_2_rounded,
              'Productos importados',
              '$importedProducts',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
