import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/categoria_repository.dart';

enum OrdenamientoCatalogo { nombreAZ, nombreZA, categoria, codigo }

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();
  final CategoriaRepository _catRepo = CategoriaRepository();

  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;
  OrdenamientoCatalogo _ordenActual = OrdenamientoCatalogo.nombreAZ;

  List<ProductoModel> get productos => _productos;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrdenamientoCatalogo get ordenActual => _ordenActual;

  Future<void> cargarProductos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _productos = await _repository.obtenerTodos();
      _aplicarOrdenamiento();
    } catch (e) {
      _errorMessage = e.toString();
      _productos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recargarProductos() => cargarProductos();

  Future<void> cargarCategorias() async {
    try {
      _categorias = await _catRepo.obtenerTodas();
      notifyListeners();
    } catch (e) { print("Error cat: $e"); }
  }

  // ✅ NUEVO: Crear Categoría al vuelo
  Future<void> crearCategoria(String nombre, String codigo) async {
    try {
      final nuevaCat = CategoriaModel(
        codigo: codigo,
        nombre: nombre,
        orden: 99, // Al final por defecto
        createdAt: DateTime.now().toIso8601String(),
      );
      await _catRepo.crear(nuevaCat);
      // Actualizamos la lista local
      _categorias.add(nuevaCat);
      notifyListeners();
    } catch (e) {
      print("Error creando categoría automática: $e");
    }
  }

  Future<String> generarCodigoParaCategoria(String catId) async {
    return await _repository.generarSiguienteCodigo(catId);
  }

  Future<void> buscarProductos(String query) async {
    if (query.isEmpty) return cargarProductos();
    _isLoading = true;
    notifyListeners();
    try {
      _productos = await _repository.buscar(query);
      _aplicarOrdenamiento();
    } catch (e) { print(e); } finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> importarProductos(List<ProductoModel> lista) async {
    try {
      await _repository.importarMasivos(lista);
      await cargarProductos();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> eliminarProducto(String id) async {
    try {
      await _repository.eliminar(id);
      _productos.removeWhere((p) => p.id == id || p.codigo == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void cambiarOrden(OrdenamientoCatalogo orden) {
    _ordenActual = orden;
    _aplicarOrdenamiento();
    notifyListeners();
  }

  void _aplicarOrdenamiento() {
    switch (_ordenActual) {
      case OrdenamientoCatalogo.nombreAZ: _productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())); break;
      case OrdenamientoCatalogo.nombreZA: _productos.sort((a, b) => b.nombre.toLowerCase().compareTo(a.nombre.toLowerCase())); break;
      case OrdenamientoCatalogo.codigo: _productos.sort((a, b) => a.codigo.compareTo(b.codigo)); break;
      case OrdenamientoCatalogo.categoria:
        _productos.sort((a, b) => (a.categoriaNombre ?? '').compareTo(b.categoriaNombre ?? ''));
        break;
    }
  }

  void limpiarBusqueda() => cargarProductos();
}