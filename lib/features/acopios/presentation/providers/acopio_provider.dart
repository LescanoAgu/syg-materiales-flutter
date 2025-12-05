import 'package:flutter/material.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _repository = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  List<AcopioModel> _acopios = [];
  List<ProveedorModel> _proveedores = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AcopioModel> get acopios => _acopios;
  List<ProveedorModel> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- CARGA DE DATOS ---
  Future<void> cargarDatos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        _cargarAcopios(),
        _cargarProveedores(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cargarAcopios() async {
    _acopios = await _repository.obtenerActivos();
  }

  // ✅ Método público requerido por las pantallas de proveedores
  Future<void> cargarProveedores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
    } catch (e) {
      print("Error proveedores: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Método de carga inicial privado (para usar dentro de cargarDatos)
  Future<void> _cargarProveedores() async {
    _proveedores = await _proveedorRepo.obtenerTodos();
  }

  // --- GESTIÓN DE PROVEEDORES (Faltaban estos métodos) ---

  Future<bool> crearProveedor(ProveedorModel p) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.crear(p);
      await _cargarProveedores();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> actualizarProveedor(ProveedorModel p) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.actualizar(p);
      await _cargarProveedores();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await _proveedorRepo.eliminar(id);
      _proveedores.removeWhere((p) => p.id == id || p.codigo == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

  // --- GESTIÓN DE ACOPIOS (Facturas) ---

  List<AcopioModel> buscar(String query) {
    if (query.isEmpty) return _acopios;
    final q = query.toLowerCase();
    return _acopios.where((a) =>
    a.clienteRazonSocial.toLowerCase().contains(q) ||
        a.etiqueta.toLowerCase().contains(q) ||
        a.numeroFactura.toLowerCase().contains(q)
    ).toList();
  }

  Future<bool> registrarIngreso(AcopioModel acopio) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.crearAcopio(acopio);
      await _cargarAcopios();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}