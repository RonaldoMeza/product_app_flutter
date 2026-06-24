import 'package:flutter/material.dart';
import '../repositories/producto_repository.dart';
import '../repositories/categoria_repository.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../widgets/producto_card.dart';
import 'producto_form_screen.dart';

class ProductoListScreen extends StatefulWidget {
  final bool filterLowStock;

  const ProductoListScreen({super.key, this.filterLowStock = false});

  @override
  State<ProductoListScreen> createState() => _ProductoListScreenState();
}

class _ProductoListScreenState extends State<ProductoListScreen> {
  final _searchController = TextEditingController();
  final _productoRepo = ProductoRepository();
  final _categoriaRepo = CategoriaRepository();
  List<Producto> _productos = [];
  List<Producto> _filtered = [];
  List<Categoria> _categorias = [];
  int? _selectedCategoriaId;
  bool _loading = true;
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    _showLowStock = widget.filterLowStock;
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productos = await _productoRepo.getAll();
    final categorias = await _categoriaRepo.getAll();
    if (!mounted) return;
    setState(() {
      _productos = productos;
      _categorias = categorias;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _productos.where((p) {
        if (_showLowStock && p.stock > 10) {
          return false;
        }
        if (_selectedCategoriaId != null &&
            p.categoriaId != _selectedCategoriaId) {
          return false;
        }
        if (query.isNotEmpty && !p.nombre.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _deleteProducto(Producto p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar producto'),
        content:
            Text('¿Eliminar "${p.nombre}"? Esta acción no se puede deshacer.'),
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
      await _productoRepo.delete(p.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        centerTitle: false,
        actions: [
          if (_showLowStock)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Bajo stock'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() => _showLowStock = false);
                  _applyFilters();
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar productos...',
              leading: const Icon(Icons.search),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
              elevation: WidgetStateProperty.all(0),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
          if (_categorias.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildFilterChip(null, 'Todas'),
                  ..._categorias.map(
                    (c) => _buildFilterChip(c.id, c.nombre),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64,
                                color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega tu primer producto',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: ListView.builder(
                          key: ValueKey(
                              '${_selectedCategoriaId}_$_showLowStock'),
                          padding:
                              const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return ProductoCard(
                              producto: p,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductoFormScreen(producto: p),
                                  ),
                                );
                                _loadData();
                              },
                              onEdit: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductoFormScreen(producto: p),
                                  ),
                                );
                                _loadData();
                              },
                              onDelete: () => _deleteProducto(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductoFormScreen()),
          );
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildFilterChip(int? id, String label) {
    final selected = _selectedCategoriaId == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedCategoriaId = id);
          _applyFilters();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
    );
  }
}
