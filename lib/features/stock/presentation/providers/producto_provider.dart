import 'package:flutter/material.dart';
import '../../data/models/producto_model.dart';
import '../../data/repositories/producto_repository.dart';

// ✅ FIX: EL ENUM AHORA VIVE SOLAMENTE AQUÍ (Fuente de verdad única)
enum OrdenamientoCatalogo {
  nombreAZ,
  nombreZA,
  categoria, // Por Tipo
  codigo,    // Por Cód
}

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();

  List<ProductoModel> _productos = [];
  bool _isLoading = false;
  String? _errorMessage;

  OrdenamientoCatalogo _ordenActual = OrdenamientoCatalogo.nombreAZ;

  List<ProductoModel> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrdenamientoCatalogo get ordenActual => _ordenActual;

  int get totalProductos => _productos.length;
  bool get hayProductos => _productos.isNotEmpty;

  Future<void> cargarProductos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _productos = await _repository.obtenerTodos();
      _aplicarOrdenamiento();
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
      _aplicarOrdenamiento();
    } catch (e) {
      print('Error buscando: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> importarProductos(List<ProductoModel> nuevosProductos) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.importarMasivos(nuevosProductos);
      await Future.delayed(const Duration(milliseconds: 500));
      await cargarProductos();
      return true;
    } catch (e) {
      _errorMessage = "Error en importación: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void cambiarOrden(OrdenamientoCatalogo nuevoOrden) {
    if (_ordenActual != nuevoOrden) {
      _ordenActual = nuevoOrden;
      _aplicarOrdenamiento();
      notifyListeners();
    }
  }

  void _aplicarOrdenamiento() {
    switch (_ordenActual) {
      case OrdenamientoCatalogo.nombreAZ:
        _productos.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        break;
      case OrdenamientoCatalogo.nombreZA:
        _productos.sort((a, b) => b.nombre.toLowerCase().compareTo(a.nombre.toLowerCase()));
        break;
      case OrdenamientoCatalogo.codigo:
        _productos.sort((a, b) => a.codigo.compareTo(b.codigo));
        break;
      case OrdenamientoCatalogo.categoria:
        _productos.sort((a, b) {
          int cmp = (a.categoriaNombre ?? '').compareTo(b.categoriaNombre ?? '');
          if (cmp == 0) {
            return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
          }
          return cmp;
        });
        break;
    }
  }

  void limpiarBusqueda() {
    cargarProductos();
  }
}