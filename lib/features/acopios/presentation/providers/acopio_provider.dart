import 'package:flutter/material.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ProveedorModel> _proveedores = [];
  List<ProveedorModel> get proveedores => _proveedores;

  List<AcopioModel> _acopios = [];
  List<AcopioModel> get acopios => _acopios;

  // --- NUEVO: Lista de items para la vista de detalle de cliente ---
  List<AcopioItem> _itemsCliente = [];
  List<AcopioItem> get itemsDeCliente => _itemsCliente;

  // --- PROVEEDORES ---
  Future<void> cargarProveedores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _proveedores = await _proveedorRepo.obtenerProveedores();
    } catch (e) {
      print("Error cargando proveedores: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearProveedor(ProveedorModel proveedor) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _proveedorRepo.crearProveedor(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarProveedor(ProveedorModel proveedor) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _proveedorRepo.actualizarProveedor(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ACOPIOS ---
  Future<void> cargarAcopios() async {
    _isLoading = true;
    notifyListeners();
    try {
      _acopios = await _acopioRepo.obtenerAcopios();
    } catch (e) {
      print("Error cargando acopios: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NUEVO: Cargar acopios específicos de un cliente y aplanar los items
  Future<void> cargarAcopiosDeCliente(String clienteId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Reutilizamos la lógica de obtener todos y filtramos en memoria por ahora
      // (Idealmente haríamos query en repo: where('clienteId', isEqualTo: clienteId))
      final todos = await _acopioRepo.obtenerAcopios();
      final delCliente = todos.where((a) => a.clienteId == clienteId).toList();

      // Aplanamos: Juntamos todos los items de todos los proveedores en una sola lista para ver "qué tiene el cliente"
      _itemsCliente = [];
      for (var acopio in delCliente) {
        _itemsCliente.addAll(acopio.items);
      }
    } catch (e) {
      print("Error cargando acopios de cliente: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarIngreso(AcopioModel acopio) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _acopioRepo.guardarAcopio(acopio);
      await cargarAcopios();
      return true;
    } catch (e) {
      print("Error ingreso acopio: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}