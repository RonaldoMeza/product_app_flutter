import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';
import '../models/categoria.dart';
import '../utils/validators.dart';

class CategoriaFormScreen extends StatefulWidget {
  final Categoria? categoria;

  const CategoriaFormScreen({super.key, this.categoria});

  @override
  State<CategoriaFormScreen> createState() => _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends State<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoriaRepo = CategoriaRepository();
  bool _saving = false;

  String _selectedColor = '#2196F3';

  bool get _isEditing => widget.categoria != null;

  static const List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Rojo', 'hex': '#F44336'},
    {'name': 'Rosa', 'hex': '#E91E63'},
    {'name': 'Púrpura', 'hex': '#9C27B0'},
    {'name': 'Índigo', 'hex': '#3F51B5'},
    {'name': 'Azul', 'hex': '#2196F3'},
    {'name': 'Celeste', 'hex': '#03A9F4'},
    {'name': 'Cian', 'hex': '#00BCD4'},
    {'name': 'Teal', 'hex': '#009688'},
    {'name': 'Verde', 'hex': '#4CAF50'},
    {'name': 'Lima', 'hex': '#8BC34A'},
    {'name': 'Amarillo', 'hex': '#FFEB3B'},
    {'name': 'Ámbar', 'hex': '#FFC107'},
    {'name': 'Naranja', 'hex': '#FF9800'},
    {'name': 'Café', 'hex': '#795548'},
    {'name': 'Gris', 'hex': '#9E9E9E'},
    {'name': 'Azul oscuro', 'hex': '#1A237E'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.categoria!;
      _nombreCtrl.text = c.nombre;
      _descCtrl.text = c.descripcion ?? '';
      _selectedColor = c.color ?? '#2196F3';
    }
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final categoria = Categoria(
      id: widget.categoria?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      color: _selectedColor,
      remoteId: widget.categoria?.remoteId,
      source: widget.categoria?.source,
      syncedAt: widget.categoria?.syncedAt,
    );

    if (_isEditing) {
      await _categoriaRepo.update(categoria);
    } else {
      await _categoriaRepo.insert(categoria);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar categoría' : 'Nueva categoría'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre',
                hintText: 'Nombre de la categoría',
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: Validators.validateNombre,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Descripción (opcional)',
                prefixIcon: const Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((opt) {
                final hex = opt['hex'] as String;
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexToColor(hex),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _hexToColor(hex).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
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
              label: Text(
                  _isEditing ? 'Guardar cambios' : 'Crear categoría'),
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
}
