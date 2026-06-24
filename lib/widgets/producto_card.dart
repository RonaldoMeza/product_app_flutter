import 'package:flutter/material.dart';
import '../models/producto.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductoCard({
    super.key,
    required this.producto,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Color _stockColor() {
    if (producto.stock <= 0) return Colors.red;
    if (producto.stock <= 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = _parseColor(producto.categoriaColor);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: producto.imagenUrl != null &&
                          producto.imagenUrl!.isNotEmpty
                      ? Image.network(
                          producto.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        producto.categoriaNombre ?? 'Sin categoría',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${producto.precio.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: _stockColor()),
                        const SizedBox(width: 4),
                        Text(
                          '${producto.stock}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _stockColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: onEdit,
                            style: IconButton.styleFrom(
                              foregroundColor:
                                  theme.colorScheme.onSurfaceVariant,
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: onDelete,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.red.shade300,
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                      ],
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

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    );
  }
}
