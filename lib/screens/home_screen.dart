import 'package:flutter/material.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/producto_repository.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/sync_status_card.dart';
import 'producto_list_screen.dart';
import 'categoria_list_screen.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _totalProductos = 0;
  int _totalCategorias = 0;
  int _bajoStock = 0;
  double _valorInventario = 0;
  bool _loading = true;
  String? _lastSyncAt;
  int _importedCatCount = 0;
  int _importedProdCount = 0;
  bool _hasData = false;

  final _categoriaRepo = CategoriaRepository();
  final _productoRepo = ProductoRepository();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final categorias = await _categoriaRepo.getAll();
    final totalP = await _productoRepo.getTotal();
    final totalC = categorias.length;
    final bajo = await _productoRepo.getBajoStock();
    final valor = await _productoRepo.getValorTotalInventario();
    final lastSync = await _categoriaRepo.getLastSyncAt();
    final catCount = await _categoriaRepo.countImported();
    final prodCount = await _productoRepo.countImported();

    if (!mounted) return;
    setState(() {
      _totalProductos = totalP;
      _totalCategorias = totalC;
      _bajoStock = bajo.length;
      _valorInventario = valor;
      _lastSyncAt = lastSync;
      _importedCatCount = catCount;
      _importedProdCount = prodCount;
      _hasData = totalP > 0 || totalC > 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          const ProductoListScreen(),
          const CategoriaListScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categorías',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProductApp'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              );
              _loadDashboard();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resumen',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SyncScreen(),
                              ),
                            );
                            _loadDashboard();
                          },
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('Sincronizar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Panel principal de inventario',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (!_hasData) ...[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_download_outlined,
                                size: 72,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay datos',
                                style:
                                    Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Importa productos desde la API de DummyJSON para comenzar',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SyncScreen(),
                                    ),
                                  );
                                  _loadDashboard();
                                },
                                icon: const Icon(Icons.download),
                                label: const Text(
                                  'Sincronizar desde API',
                                ),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.1,
                        children: [
                          DashboardCard(
                            title: 'Productos',
                            value: '$_totalProductos',
                            icon: Icons.inventory_2_rounded,
                            color: Colors.indigo,
                            onTap: () {
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          DashboardCard(
                            title: 'Categorías',
                            value: '$_totalCategorias',
                            icon: Icons.category_rounded,
                            color: Colors.teal,
                            onTap: () {
                              setState(() => _currentIndex = 2);
                            },
                          ),
                          DashboardCard(
                            title: 'Bajo stock',
                            value: '$_bajoStock',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductoListScreen(
                                    filterLowStock: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          DashboardCard(
                            title: 'Valor inventario',
                            value:
                                '\$${_valorInventario.toStringAsFixed(0)}',
                            icon: Icons.attach_money_rounded,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SyncStatusCard(
                        lastSyncAt: _lastSyncAt,
                        importedCategories: _importedCatCount,
                        importedProducts: _importedProdCount,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}
