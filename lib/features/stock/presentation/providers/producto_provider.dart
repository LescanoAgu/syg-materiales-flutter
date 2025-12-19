import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/producto_repository.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();

  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  List<CategoriaModel> _categorias = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<ProductoModel> get productos => _searchQuery.isEmpty ? _productos : _productosFiltrados;
  List<CategoriaModel> get categorias => _categorias;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  String _searchQuery = "";

  // ✅ MÉTODO QUE FALTABA
  Future<String> generarCodigoParaCategoria(String categoriaId) async {
    // Genera un código simple: Primera letra de cat + timestamp
    return "${categoriaId.substring(0, 1).toUpperCase()}${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  }

  Future<void> cargarProductos({bool recargar = false}) async {
    if (recargar) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _productos = await _repository.obtenerProductos();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Error cargando productos: $e";
      _productos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCategorias() async {
    try {
      _categorias = await _repository.obtenerCategorias();
      notifyListeners();
    } catch (e) {
      print("Error cargando categorías: $e");
    }
  }

  Future<void> buscarProductos(String query) async {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _productosFiltrados = [];
      notifyListeners();
      return;
    }
    final terms = _normalize(_searchQuery).split(' ');
    _productosFiltrados = _productos.where((p) {
      final nombreNorm = _normalize(p.nombre);
      final codigoNorm = _normalize(p.codigo);
      final catNorm = _normalize(p.categoriaNombre ?? '');
      return terms.every((term) =>
      nombreNorm.contains(term) || codigoNorm.contains(term) || catNorm.contains(term));
    }).toList();
    notifyListeners();
  }

  Future<void> buscarParaDelegate(String query) async {
    return buscarProductos(query);
  }

  String _normalize(String input) {
    return input.toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  Future<void> crearCategoria(String nombre, String codigo, String prefijo) async {
    try {
      final nuevaCat = CategoriaModel(
          id: '',
          nombre: nombre,
          codigo: codigo,
          prefijo: prefijo,
          orden: 0
      );
      await _repository.guardarCategoria(nuevaCat);
      await cargarCategorias();
    } catch (e) {
      print("Error creando categoría auto: $e");
    }
  }

  Future<bool> importarProductos(List<ProductoModel> lista) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.guardarLote(lista);
      await cargarProductos(recargar: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarProducto(ProductoModel producto) async {
    try {
      await _repository.guardar(producto);
      await cargarProductos();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await _repository.eliminar(id);
      await cargarProductos();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }
}