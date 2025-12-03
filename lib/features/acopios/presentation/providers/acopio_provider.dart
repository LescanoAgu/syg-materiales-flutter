import 'package:flutter/material.dart';
import '../../data/models/billetera_acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  // Estado
  List<BilleteraAcopio> _billeteras = [];
  List<BilleteraAcopio> _billeterasFiltradas = [];
  List<ProveedorModel> _proveedores = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters Principales
  List<BilleteraAcopio> get acopios => _billeterasFiltradas.isEmpty && _searchQuery.isEmpty ? _billeteras : _billeterasFiltradas;
  List<ProveedorModel> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String _searchQuery = '';

  // Getters de UI
  int get totalAcopios => acopios.length;
  int get totalClientes => acopios.map((b) => b.clienteId).toSet().length;
  int get totalProveedores => _proveedores.length;

  // --- CARGA INICIAL ---
  Future<void> cargarTodo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        cargarBilleteras(),
        cargarProveedores(),
      ]);
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => cargarTodo();

  Future<void> cargarBilleteras() async {
    try {
      _billeteras = await _acopioRepo.obtenerBilleterasConSaldo();
      _aplicarFiltros();
    } catch (e) {
      print("Error billeteras: $e");
    }
  }

  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
      notifyListeners();
    } catch (e) {
      print("Error proveedores: $e");
    }
  }

  // --- FILTROS ---
  void buscarPorProducto(String query) {
    _searchQuery = query;
    _aplicarFiltros();
    notifyListeners();
  }

  void limpiarFiltros() {
    _searchQuery = '';
    _billeterasFiltradas = [];
    notifyListeners();
  }

  void _aplicarFiltros() {
    if (_searchQuery.isEmpty) {
      _billeterasFiltradas = [];
      return;
    }
    final q = _searchQuery.toLowerCase();
    _billeterasFiltradas = _billeteras.where((b) =>
    b.clienteNombre.toLowerCase().contains(q) ||
        b.productoNombre.toLowerCase().contains(q)
    ).toList();
  }

  // --- MOVIMIENTOS ---
  Future<bool> registrarMovimiento({
    required String clienteId,
    required String clienteNombre,
    required String productoId,
    required String productoNombre,
    required double cantidad,
    required String proveedorId,
    required dynamic tipo,
    String? motivo,
    String? facturaNumero,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String tipoStr = tipo.toString().split('.').last;

      await _acopioRepo.registrarMovimiento(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        productoId: productoId,
        productoNombre: productoNombre,
        cantidad: cantidad,
        origenDestinoId: proveedorId,
        tipoMovimiento: tipoStr,
        referencia: facturaNumero ?? motivo,
      );

      await cargarBilleteras();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarTraspaso({
    required String productoCodigo,
    required String origenClienteCodigo,
    required String origenProveedorCodigo,
    required String destinoClienteCodigo,
    required String destinoProveedorCodigo,
    required double cantidad,
    String? motivo,
    String? referencia,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Salida
      await _acopioRepo.registrarMovimiento(
        clienteId: origenClienteCodigo,
        clienteNombre: "Cliente", // Deberías buscar nombre real si es posible
        productoId: productoCodigo,
        productoNombre: "Producto",
        cantidad: -cantidad,
        origenDestinoId: origenProveedorCodigo,
        tipoMovimiento: 'traspaso_salida',
        referencia: 'Traspaso a $destinoProveedorCodigo',
      );

      // 2. Entrada
      await _acopioRepo.registrarMovimiento(
        clienteId: destinoClienteCodigo,
        clienteNombre: "Cliente",
        productoId: productoCodigo,
        productoNombre: "Producto",
        cantidad: cantidad,
        origenDestinoId: destinoProveedorCodigo,
        tipoMovimiento: 'traspaso_entrada',
        referencia: 'Traspaso desde $origenProveedorCodigo',
      );

      await cargarBilleteras();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE HISTORIAL QUE FALTABAN ---

  // 1. Para AcopioDetallePage
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    required String productoCodigo,
    required String clienteCodigo,
  }) async {
    return await _acopioRepo.obtenerHistorialAcopio(
      productoId: productoCodigo,
      clienteId: clienteCodigo,
    );
  }

  // 2. Para ProveedorDetallePage (NUEVO)
  Future<List<MovimientoAcopioModel>> obtenerMovimientosProveedor(String proveedorId) async {
    return await _acopioRepo.obtenerMovimientosPorUbicacion(proveedorId);
  }

  // --- PROVEEDORES ---
  Future<bool> crearProveedor(ProveedorModel p) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.crear(p);
      await cargarProveedores();
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
      await cargarProveedores();
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

  // Placeholders
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async => [];
  Future<void> filtrarPorFactura(String factura) async {}
}