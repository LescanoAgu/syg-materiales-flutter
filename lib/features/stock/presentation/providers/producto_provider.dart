// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Importar para usar groupBy, aunque lo haré manualmente
import '../../data/models/producto_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Provider de Productos con Stock (Versión Firebase)
class ProductoProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIOS
  // ========================================

  final ProductoRepository _repository = ProductoRepository();
  final StockRepository _stockRepository = StockRepository();

  // ========================================
  // ESTADO
  // ========================================

  /// Lista de productos CON stock
  List<ProductoConStock> _productos = [];

  /// Producto seleccionado actualmente
  ProductoConStock? _productoSeleccionado;

  /// Estado de carga
  bool _isLoading = false;

  /// Mensaje de error (si hay)
  String? _errorMessage;

  /// Término de búsqueda actual
  String _searchTerm = '';

  /// Filtro de categoría actual (null = todas)
  String? _categoriaFiltroCodigo; // CAMBIO: Ahora es el código (String)

  // ========================================
  // GETTERS
  // ========================================

  List<ProductoConStock> get productos => _productos;
  ProductoConStock? get productoSeleccionado => _productoSeleccionado;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchTerm => _searchTerm;
  String? get categoriaFiltroCodigo => _categoriaFiltroCodigo;

  bool get hayProductos => _productos.isNotEmpty;
  int get totalProductos => _productos.length;
  // Estos helpers están bien, se basan en _productos
  int get productosStockBajo => _productos.where((p) => p.stockBajo).length;
  int get productosSinStock => _productos.where((p) => p.sinStock).length;


  // ========================================
  // OPERACIONES DE CARGA (MERGE LOGIC)
  // ========================================

  /// Carga todos los productos con su stock (Fusiona datos en Dart)
  Future<void> cargarProductos() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. Obtener todos los productos (con su categoría desnormalizada)
      final productosBase = await _repository.obtenerTodosConCategoria(soloActivos: true);

      // 2. Obtener todos los registros de stock
      final stockList = await _stockRepository.obtenerTodos();

      // 3. Crear un mapa para un acceso rápido al stock (codigo: StockModel)
      final stockMap = { for (var s in stockList) s.productoId: s };

      // 4. Fusionar los datos en la lista final (ProductoConStock)
      _productos = productosBase.map((p) {
        final stock = stockMap[p.producto.codigo];
        final cantidadDisponible = stock?.cantidadDisponible ?? 0.0;

        return ProductoConStock(
          productoId: p.producto.id!, // El ID/Código (String)
          productoCodigo: p.producto.codigo,
          productoNombre: p.producto.nombre,
          unidadBase: p.producto.unidadBase,
          equivalencia: p.producto.equivalencia,
          precioSinIva: p.producto.precioSinIva,
          categoriaId: p.producto.categoriaId, // Mantenemos el int para compatibilidad
          categoriaNombre: p.categoriaNombre,
          categoriaCodigo: p.categoriaCodigo,
          cantidadDisponible: cantidadDisponible,
        );
      }).toList();

      // 5. Aplicar filtros si existen (para refrescar manteniendo el filtro)
      _aplicarFiltrosLocales();


      _isLoading = false;
      notifyListeners();

      print('✅ ${_productos.length} productos cargados y fusionados con stock');

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar productos: $e';
      notifyListeners();

      print('❌ Error al cargar productos: $e');
    }
  }

  /// Lógica de filtrado local después de cargar/refrescar
  void _aplicarFiltrosLocales() {
    if (_searchTerm.isNotEmpty) {
      _productos = _productos.where((p) =>
      p.productoNombre.toLowerCase().contains(_searchTerm) ||
          p.productoCodigo.toLowerCase().contains(_searchTerm) ||
          p.categoriaNombre.toLowerCase().contains(_searchTerm)
      ).toList();
    }

    if (_categoriaFiltroCodigo != null) {
      _productos = _productos
          .where((p) => p.categoriaCodigo == _categoriaFiltroCodigo)
          .toList();
    }
  }

  Future<void> recargarProductos() async {
    await cargarProductos();
  }

  // ========================================
  // BÚSQUEDA Y FILTROS
  // ========================================

  /// Busca productos por término
  Future<void> buscarProductos(String termino) async {
    _isLoading = true;
    _searchTerm = termino.trim().toLowerCase();
    _errorMessage = null;
    notifyListeners();

    // La búsqueda se delega al repositorio de Productos (que usa startsWith)
    // Pero solo si se busca por nombre/código
    if (termino.trim().isEmpty) {
      await cargarProductos();
    } else {
      // Recargar y filtrar localmente (incluye nombre, código y categoría)
      await cargarProductos(); // Recarga la lista completa
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Filtra productos por categoría
  Future<void> filtrarPorCategoria(String? categoriaCodigo) async { // CAMBIO: String
    _isLoading = true;
    _categoriaFiltroCodigo = categoriaCodigo;
    _errorMessage = null;
    notifyListeners();

    await cargarProductos(); // Recarga y aplica el filtro localmente

    _isLoading = false;
    notifyListeners();
  }


  // ========================================
  // OPERACIONES CRUD
  // ========================================

  /// Crea un nuevo producto
  Future<bool> crearProducto(ProductoModel producto) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // El repo ya no devuelve un ID, solo crea el doc con el código
      await _repository.crear(producto);

      await cargarProductos();

      _isLoading = false;
      notifyListeners();

      print('✅ Producto creado con código: ${producto.codigo}');
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear producto: $e';
      notifyListeners();

      print('❌ Error al crear producto: $e');
      return false;
    }
  }

  /// Desactiva un producto (soft delete)
  /// CAMBIO: Ahora recibe el código (String)
  Future<bool> desactivarProducto(String codigo) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.desactivar(codigo); // Llamada con código

      await cargarProductos();

      _isLoading = false;
      notifyListeners();

      print('✅ Producto desactivado');
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al desactivar: $e';
      notifyListeners();

      print('❌ Error al desactivar producto: $e');
      return false;
    }
  }

// (ActualizarProducto sigue la misma lógica que crearProducto)
}