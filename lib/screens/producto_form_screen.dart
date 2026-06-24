import 'package:flutter/material.dart';
import '../repositories/producto_repository.dart';
import '../repositories/categoria_repository.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../utils/validators.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  final _productoRepo = ProductoRepository();
  final _categoriaRepo = CategoriaRepository();

  int? _categoriaId;
  List<Categoria> _categorias = [];
  bool _saving = false;
  bool get _isEditing => widget.producto != null;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    if (_isEditing) {
      final p = widget.producto!;
      _nombreCtrl.text = p.nombre;
      _descCtrl.text = p.descripcion ?? '';
      _precioCtrl.text = p.precio.toStringAsFixed(2);
      _stockCtrl.text = p.stock.toString();
      _imagenCtrl.text = p.imagenUrl ?? '';
      _categoriaId = p.categoriaId;
    }
  }

  Future<void> _loadCategorias() async {
    final cats = await _categoriaRepo.getAll();
    setState(() => _categorias = cats);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una categoría')),
      );
      return;
    }
    setState(() => _saving = true);

    final producto = Producto(
      id: widget.producto?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      precio: double.parse(_precioCtrl.text.replaceAll(',', '.')),
      stock: int.parse(_stockCtrl.text),
      imagenUrl: _imagenCtrl.text.trim().isEmpty
          ? null
          : _imagenCtrl.text.trim(),
      categoriaId: _categoriaId!,
      fechaCreacion: widget.producto?.fechaCreacion ??
          DateTime.now().toIso8601String(),
      remoteId: widget.producto?.remoteId,
      source: widget.producto?.source,
      syncedAt: widget.producto?.syncedAt,
      isLocalEdited: widget.producto?.isLocalEdited ?? 0,
    );

    if (_isEditing) {
      await _productoRepo.update(producto);
    } else {
      await _productoRepo.insert(producto);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _imagenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Información general'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Nombre del producto',
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
              ),
              validator: Validators.validateNombre,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción del producto (opcional)',
                prefixIcon: const Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            _buildSection('Precio y stock'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioCtrl,
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.validatePrecio,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    decoration: InputDecoration(
                      labelText: 'Stock',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection('Categoría'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _categoriaId,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: _categorias.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.nombre),
                );
              }).toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
              validator: Validators.validateCategoria,
            ),
            const SizedBox(height: 24),
            _buildSection('Imagen'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imagenCtrl,
              decoration: InputDecoration(
                labelText: 'URL de imagen',
                hintText: 'https://ejemplo.com/imagen.jpg',
                prefixIcon: const Icon(Icons.image_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            if (_imagenCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagenCtrl.text,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_isEditing ? Icons.save : Icons.add_circle_outline),
              label:
                  Text(_isEditing ? 'Guardar cambios' : 'Crear producto'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
