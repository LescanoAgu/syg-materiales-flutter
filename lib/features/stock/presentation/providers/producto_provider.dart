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
  String? _errorMessage;

  List<ProductoModel> get productos => _searchQuery.isEmpty ? _productos : _productosFiltrados;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;

  String _searchQuery = "";

  // ✅ NUEVO GENERADOR: Soporta prefijos largos (OG, AR, A-)
  Future<String> generarCodigoParaCategoria(String prefijoCategoria) async {
    // Limpiamos el prefijo por si acaso
    final prefix = prefijoCategoria.toUpperCase();

    // Filtramos productos que comiencen exactamente con ese prefijo
    final productosDeCat = _productos.where((p) => p.codigo.toUpperCase().startsWith(prefix)).toList();

    if (productosDeCat.isEmpty) {
      // Si no hay ninguno, arrancamos con el 001
      // Ej: OG001
      return "${prefix}001";
    }

    int maxNum = 0;
    for (var p in productosDeCat) {
      // Quitamos el prefijo para quedarnos solo con el número
      // Ej: OG025 -> "025" -> 25
      try {
        String parteNumerica = p.codigo.toUpperCase().replaceFirst(prefix, '');
        // Limpiamos cualquier otro caracter raro (guiones extra si hubiere)
        parteNumerica = parteNumerica.replaceAll(RegExp(r'[^0-9]'), '');

        if (parteNumerica.isNotEmpty) {
          int num = int.parse(parteNumerica);
          if (num > maxNum) maxNum = num;
        }
      } catch (_) {}
    }

    int siguiente = maxNum + 1;
    // Formateamos siempre a 3 dígitos (001, 010, 100)
    return "$prefix${siguiente.toString().padLeft(3, '0')}";
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
      // Verificamos si ya existe en la lista local para no llamar a Firebase en vano
      bool existe = _categorias.any((c) => c.codigo == codigo);
      if (existe) return;

      final nuevaCat = CategoriaModel(
          id: codigo,
          nombre: nombre,
          codigo: codigo,
          prefijo: prefijo,
          orden: 0
      );
      await _repository.guardarCategoria(nuevaCat);

      // Actualizamos localmente
      _categorias.add(nuevaCat);
      notifyListeners();
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