import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/producto_provider.dart';
import '../../data/models/stock_model.dart';

/// Pantalla principal de Stock
///
/// Muestra la lista de productos con búsqueda y filtros.
/// Diseño inspirado en modern_design_desktop.tsx
class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar productos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // APP BAR con gradiente
      // ========================================
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock de Materiales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Consumer<ProductoProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.totalProductos} productos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Mostrar diálogo de filtros
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros próximamente')),
              );
            },
          ),
        ],
      ),

      // ========================================
      // BODY
      // ========================================
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            // ========================================
            // BARRA DE BÚSQUEDA
            // ========================================
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por código, nombre o categoría...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<ProductoProvider>().limpiarBusqueda();
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: AppColors.backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Búsqueda en tiempo real
                  context.read<ProductoProvider>().buscarProductos(value);
                  setState(() {}); // Para actualizar el icono clear
                },
              ),
            ),

            // ========================================
            // LISTA DE PRODUCTOS
            // ========================================
            Expanded(
              child: Consumer<ProductoProvider>(
                builder: (context, provider, child) {
                  // Estado de carga
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  // Error
                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.cargarProductos(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sin productos
                  if (!provider.hayProductos) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Comienza agregando productos',
                            style: TextStyle(
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Lista de productos
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => provider.recargarProductos(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.productos.length,
                      itemBuilder: (context, index) {
                        final item = provider.productos[index];
                        return _ProductoCard(productoConStock: item);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ========================================
      // FLOATING ACTION BUTTON
      // ========================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navegar a pantalla de crear producto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear producto próximamente')),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Material'),
      ),
    );
  }
}

// ========================================
// CARD DE PRODUCTO
// ========================================

class _ProductoCard extends StatelessWidget {
  final ProductoConStock productoConStock;

  const _ProductoCard({required this.productoConStock});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle del producto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detalle de ${productoConStock.productoNombre}')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // HEADER: Código + Categoría + Stock Badge
              // ========================================
              Row(
                children: [
                  // Código del producto
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      productoConStock.productoCodigo,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Categoría
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '[${productoConStock.categoriaCodigo}] ${productoConStock.categoriaNombre}',
                      style: const TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Badge de Stock
                  _buildStockBadge(productoConStock),
                ],
              ),

              const SizedBox(height: 12),

              // ========================================
              // NOMBRE DEL PRODUCTO
              // ========================================
              Text(
                productoConStock.productoNombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 12),

              // ========================================
              // INFO: Stock + Unidad + Precio
              // ========================================
              Row(
                children: [
                  // Stock Disponible
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 20,
                              color: _getStockColor(productoConStock),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${productoConStock.cantidadFormateada} ${productoConStock.unidadCompleta}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _getStockColor(productoConStock),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Precio
                  if (productoConStock.precioSinIva != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Precio',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            productoConStock.precioFormateado,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Badge de estado del stock
  Widget _buildStockBadge(ProductoConStock producto) {
    if (producto.sinStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.error, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning, size: 12, color: AppColors.error),
            SizedBox(width: 4),
            Text(
              'SIN STOCK',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (producto.stockBajo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_amber, size: 12, color: AppColors.warning),
            SizedBox(width: 4),
            Text(
              'STOCK BAJO',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Stock OK
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, size: 12, color: AppColors.success),
          SizedBox(width: 4),
          Text(
            'OK',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Color según el nivel de stock
  Color _getStockColor(ProductoConStock producto) {
    if (producto.sinStock) return AppColors.error;
    if (producto.stockBajo) return AppColors.warning;
    return AppColors.success;
  }
}