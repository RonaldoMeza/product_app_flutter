import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';
import '../models/categoria.dart';
import 'categoria_form_screen.dart';

class CategoriaListScreen extends StatefulWidget {
  const CategoriaListScreen({super.key});

  @override
  State<CategoriaListScreen> createState() => _CategoriaListScreenState();
}

class _CategoriaListScreenState extends State<CategoriaListScreen> {
  final _categoriaRepo = CategoriaRepository();
  List<Categoria> _categorias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await _categoriaRepo.getAll();
    if (!mounted) return;
    setState(() {
      _categorias = cats;
      _loading = false;
    });
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.grey;
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _deleteCategoria(Categoria c) async {
    final hasProducts = await _categoriaRepo.hasProducts(c.id!);
    if (!mounted) return;

    if (hasProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${c.nombre}" tiene productos asociados. Elimine o reasigne los productos primero.',
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${c.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _categoriaRepo.delete(c.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categorias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No hay categorías',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primera categoría',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _categorias.length,
                    itemBuilder: (_, i) {
                      final c = _categorias[i];
                      final color = _parseColor(c.color);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoriaFormScreen(categoria: c),
                              ),
                            );
                            _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.category_rounded,
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.nombre,
                                        style:
                                            theme.textTheme.titleMedium
                                                ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (c.descripcion != null &&
                                          c.descripcion!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          c.descripcion!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (c.source == 'dummyjson')
                                  Tooltip(
                                    message: 'Importado desde API',
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.cloud_done_outlined,
                                        size: 18,
                                        color: Colors.blue.shade300,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red.shade300),
                                  onPressed: () => _deleteCategoria(c),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CategoriaFormScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}
