import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/producto_repository.dart';
import '../widgets/sync_status_card.dart';
import 'home_screen.dart';

class SyncScreen extends StatefulWidget {
  final bool firstTime;

  const SyncScreen({super.key, this.firstTime = false});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _api = ApiService();
  final _categoriaRepo = CategoriaRepository();
  final _productoRepo = ProductoRepository();

  bool _syncing = false;
  String? _error;
  int? _importedCategories;
  int? _importedProducts;
  String? _lastSyncAt;
  int _importedCatCount = 0;
  int _importedProdCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    final lastSync = await _categoriaRepo.getLastSyncAt();
    final catCount = await _categoriaRepo.countImported();
    final prodCount = await _productoRepo.countImported();
    if (!mounted) return;
    setState(() {
      _lastSyncAt = lastSync;
      _importedCatCount = catCount;
      _importedProdCount = prodCount;
    });
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _error = null;
      _importedCategories = null;
      _importedProducts = null;
    });

    try {
      final apiCategories = await _api.fetchCategories();
      final catsInserted = await _categoriaRepo.syncFromApi(apiCategories);

      final categoryMapping = await _categoriaRepo.getRemoteIdMapping();
      final apiProducts = await _api.fetchProducts(limit: 100);
      final prodsInserted = await _productoRepo.syncFromApi(
        apiProducts,
        categoryMapping,
      );

      if (!mounted) return;
      setState(() {
        _importedCategories = catsInserted;
        _importedProducts = prodsInserted;
        _syncing = false;
      });
      await _loadSyncInfo();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _syncing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión: $e';
        _syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SyncStatusCard(
            lastSyncAt: _lastSyncAt,
            importedCategories: _importedCatCount,
            importedProducts: _importedProdCount,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar desde API'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_importedCategories != null || _importedProducts != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Sincronización completada',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _resultRow(
                        Icons.category_rounded,
                        'Categorías importadas',
                        '${_importedCategories ?? 0}',
                        Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      _resultRow(
                        Icons.inventory_2_rounded,
                        'Productos importados',
                        '${_importedProducts ?? 0}',
                        Colors.indigo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.firstTime && _importedProducts != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ir al inicio'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
