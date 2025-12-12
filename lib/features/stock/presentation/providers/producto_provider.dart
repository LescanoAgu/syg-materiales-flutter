import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/categoria_repository.dart';

enum OrdenamientoCatalogo { nombreAZ, nombreZA, categoria, codigo }

class ProductoProvider extends ChangeNotifier {
  final ProductoRepository _repository = ProductoRepository();
  final CategoriaRepository _catRepo = CategoriaRepository();

  // --- ESTADO ---
  List<ProductoModel> _productos = [];
  List<CategoriaModel> _categorias = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Filtros
  OrdenamientoCatalogo _ordenActual = OrdenamientoCatalogo.codigo;
  String? _categoriaFiltroId;
  DocumentSnapshot? _ultimoDocumento;
  bool _hayMas = true;

  // --- GETTERS ---
  List<ProductoModel> get productos => _productos;
  List<CategoriaModel> get categorias => _categorias;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get categoriaFiltroId => _categoriaFiltroId;

  // --- CARGA ---
  Future<void> cargarProductos({bool recargar = false}) async {
    if (recargar) {
      _ultimoDocumento = null;
      _productos = [];
      _hayMas = true;
    }
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _repository.obtenerPaginados(
        limite: 20,
        ordenarPor: _mapearOrdenamiento(),
        filtroCategoriaId: _categoriaFiltroId,
      );
      _procesarSnapshot(snapshot);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarMasProductos() async {
    if (_isLoadingMore || !_hayMas || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final snapshot = await _repository.obtenerPaginados(
        limite: 20,
        ultimoDocumento: _ultimoDocumento,
        ordenarPor: _mapearOrdenamiento(),
        filtroCategoriaId: _categoriaFiltroId,
      );
      _procesarSnapshot(snapshot);
    } catch (e) {
      print("Error cargando más: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _procesarSnapshot(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      _hayMas = false;
      return;
    }
    _ultimoDocumento = snapshot.docs.last;
    final nuevos = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return ProductoModel.fromMap(data);
    }).toList();
    _productos.addAll(nuevos);
    if (snapshot.docs.length < 20) _hayMas = false;
  }

  // --- CATEGORÍAS (Con Prefijo) ---
  Future<void> cargarCategorias() async {
    try {
      _categorias = await _catRepo.obtenerTodas();
      notifyListeners();
    } catch (e) { print("Error cat: $e"); }
  }

  void seleccionarCategoria(String? categoriaId) {
    if (_categoriaFiltroId == categoriaId) return;
    _categoriaFiltroId = categoriaId;
    cargarProductos(recargar: true);
  }

  // ✅ CREAR CATEGORÍA CON PREFIJO
  Future<void> crearCategoria(String nombre, String codigo, String prefijo) async {
    try {
      if (_categorias.any((c) => c.codigo == codigo)) return;

      final nuevaCat = CategoriaModel(
        codigo: codigo,
        nombre: nombre,
        prefijo: prefijo, // ✅ Guardamos el prefijo
        orden: 99,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _catRepo.crear(nuevaCat);
      _categorias.add(nuevaCat);
      _categorias.sort((a,b) => a.nombre.compareTo(b.nombre));
      notifyListeners();
    } catch (e) {
      print("Error creando categoría automática: $e");
    }
  }

  // --- BÚSQUEDA Y GESTIÓN ---
  Future<void> buscarProductos(String query) async {
    if (query.isEmpty) {
      cargarProductos(recargar: true);
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _productos = await _repository.buscar(query);
      _hayMas = false;
    } catch (e) { print(e); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> importarProductos(List<ProductoModel> lista) async {
    try {
      await _repository.importarMasivos(lista);
      await cargarProductos(recargar: true);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> eliminarProducto(String id) async {
    try {
      await _repository.eliminar(id);
      _productos.removeWhere((p) => p.id == id || p.codigo == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

  Future<String> generarCodigoParaCategoria(String catId) async {
    // Buscamos la categoría para obtener su prefijo real
    final cat = _categorias.firstWhere((c) => c.codigo == catId, orElse: () => CategoriaModel(codigo: '', nombre: '', orden: 0));

    // Si la categoría tiene prefijo (ej: "A"), lo usamos. Si no, usamos una letra por defecto o el ID.
    String prefijo = cat.prefijo.isNotEmpty ? cat.prefijo : catId.substring(0, 1).toUpperCase();

    return await _repository.generarSiguienteCodigo(catId, prefijo);
  }

  Future<List<ProductoModel>> buscarParaDelegate(String query) async => await _repository.buscar(query);

  String _mapearOrdenamiento() {
    return _ordenActual == OrdenamientoCatalogo.codigo ? 'codigo' : 'nombre';
  }
}