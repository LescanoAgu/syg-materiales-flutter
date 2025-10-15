import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../providers/producto_provider.dart';
/// Pantalla de STOCK (Inventario)
///
/// Muestra los productos que tienen stock asignado.
/// Permite ajustar cantidades (entradas/salidas).
/// Los operarios NO pueden crear productos nuevos aquí.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final StockRepository _stockRepo = StockRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductoConStock> _todosLosProductos = [];
  List<ProductoConStock> _productosFiltrados = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _searchController.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoading = true);

    try {
      final productos = await _stockRepo.obtenerTodosConStock(soloActivos: true);

      setState(() {
        _todosLosProductos = productos;
        _productosFiltrados = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar stock: $e')),
        );
      }
    }
  }

  void _filtrarProductos() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _productosFiltrados = _todosLosProductos.where((producto) {
        final matchQuery = query.isEmpty ||
            producto.productoNombre.toLowerCase().contains(query) ||
            producto.productoCodigo.toLowerCase().contains(query);

        final matchCategoria = _filtroCategoria == 'Todos' ||
            producto.categoriaNombre == _filtroCategoria;

        return matchQuery && matchCategoria;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text('Stock de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
            tooltip: 'Actualizar',
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            // ========================================
            // BARRA DE BÚSQUEDA Y FILTROS
            // ========================================
            _buildSearchBar(),

            // ========================================
            // ESTADÍSTICAS
            // ========================================
            _buildEstadisticas(),

            // ========================================
            // LISTA DE PRODUCTOS
            // ========================================
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _productosFiltrados.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarAgregarAlStock(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar a Stock'),
      ),
    );
  }

  // ========================================
  // BARRA DE BÚSQUEDA
  // ========================================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por código o nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filtro por categoría
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoriaChip('Todos'),
                _buildCategoriaChip('Obra General'),
                _buildCategoriaChip('Hierros'),
                _buildCategoriaChip('Pintura'),
                _buildCategoriaChip('Sanitario'),
                _buildCategoriaChip('Eléctrico'),
                _buildCategoriaChip('Maderas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(String categoria) {
    final isSelected = _filtroCategoria == categoria;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(categoria),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroCategoria = categoria;
            _filtrarProductos();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================
  Widget _buildEstadisticas() {
    final totalProductos = _productosFiltrados.length;
    final stockBajo = _productosFiltrados
        .where((p) => p.cantidadDisponible < 10)
        .length;
    final sinStock = _productosFiltrados
        .where((p) => p.cantidadDisponible == 0)
        .length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstadistica(
            'Total',
            totalProductos.toString(),
            Icons.inventory_2,
            AppColors.primary,
          ),
          _buildEstadistica(
            'Stock Bajo',
            stockBajo.toString(),
            Icons.warning_amber,
            AppColors.warning,
          ),
          _buildEstadistica(
            'Sin Stock',
            sinStock.toString(),
            Icons.error_outline,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // ========================================
  // LISTA DE PRODUCTOS
  // ========================================
  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _productosFiltrados.length,
      itemBuilder: (context, index) {
        final productoStock = _productosFiltrados[index];
        return _buildProductoCard(productoStock);
      },
    );
  }

  Widget _buildProductoCard(ProductoConStock productoStock) {
    final cantidad = productoStock.cantidadDisponible;

    // Determinar color según stock
    Color stockColor;

    if (cantidad == 0) {
      stockColor = AppColors.error;
    } else if (cantidad < 10) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _ajustarStock(productoStock),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Indicador de stock (barra de color)
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: stockColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Código
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            productoStock.productoCodigo,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nombre
                        Expanded(
                          child: Text(
                            productoStock.productoNombre,
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Categoría
                    Text(
                      productoStock.categoriaNombre,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Stock (compacto)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cantidad.toStringAsFixed(0),
                    style: AppTextStyles.h3.copyWith(color: stockColor),
                  ),
                  Text(
                    productoStock.unidadBase,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),

              // Icono de acción
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ESTADO VACÍO
  // ========================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en stock',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos del catálogo al inventario',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========================================
  // ACCIONES
  // ========================================
  void _ajustarStock(ProductoConStock productoStock) {
    // TODO: Navegar a pantalla de ajuste de stock
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajustar stock de: ${productoStock.productoNombre}'),
      ),
    );
  }

  void _mostrarAgregarAlStock() {
    // TODO: Mostrar diálogo para seleccionar producto del catálogo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente: Agregar productos del catálogo a stock'),
      ),
    );
  }
}