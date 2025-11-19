import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/producto_repository.dart';

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();

  List<ProductoModel> _productos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductoModel> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getter para compatibilidad con UI
  int get totalProductos => _productos.length;
  bool get hayProductos => _productos.isNotEmpty;

  Future<void> cargarProductos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productos = await _repository.obtenerTodos();
    } catch (e) {
      _errorMessage = 'Error: $e';
      _productos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recargarProductos() async {
    await cargarProductos();
  }

  Future<void> buscarProductos(String query) async {
    if (query.isEmpty) {
      await cargarProductos();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _productos = await _repository.buscar(query);
    } catch (e) {
      print('Error buscando: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void limpiarBusqueda() {
    cargarProductos();
  }
}