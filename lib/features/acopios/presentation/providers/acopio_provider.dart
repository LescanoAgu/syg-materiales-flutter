import 'package:flutter/material.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';
import '../../../stock/data/repositories/producto_repository.dart';
import '../../../clientes/data/repositories/cliente_repository.dart';

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();
  final ProductoRepository _productoRepo = ProductoRepository();
  final ClienteRepository _clienteRepo = ClienteRepository();

  List<AcopioDetalle> _acopios = [];
  List<AcopioDetalle> _acopiosFiltrados = []; // Para filtros locales
  List<ProveedorModel> _proveedores = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<AcopioDetalle> get acopios => _acopiosFiltrados.isEmpty ? _acopios : _acopiosFiltrados;
  List<ProveedorModel> get proveedores => _proveedores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters para UI
  int get totalAcopios => _acopios.length;
  int get totalClientes => _acopios.map((a) => a.clienteRazonSocial).toSet().length;
  int get totalProveedores => _acopios.map((a) => a.proveedorNombre).toSet().length;
  int get totalReservas => _acopios.where((a) => a.esDepositoSyg).length;
  List<AcopioDetalle> get acopiosEnDepositoSyg => _acopios.where((a) => a.esDepositoSyg).toList();
  bool get hasData => _acopios.isNotEmpty;
  bool get hasError => _errorMessage != null;

  // --- CARGA INICIAL ---
  Future<void> cargarTodo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([cargarAcopios(), cargarProveedores()]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => cargarTodo();

  Future<void> cargarAcopios() async {
    try {
      _acopios = await _acopioRepo.obtenerTodosConDetalle();
      _acopiosFiltrados = [];
      notifyListeners();
    } catch (e) {
      print("Error cargando acopios: $e");
    }
  }

  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
      notifyListeners();
    } catch (e) {
      print("Error cargando proveedores: $e");
    }
  }

  // --- MÉTODOS DE AGRUPACIÓN Y UI ---
  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorCliente() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in acopios) {
      map.putIfAbsent(a.clienteRazonSocial, () => []).add(a);
    }
    return map;
  }

  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorProveedor() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in acopios) {
      map.putIfAbsent(a.proveedorNombre, () => []).add(a);
    }
    return map;
  }

  void buscarPorProducto(String query) {
    if (query.isEmpty) {
      _acopiosFiltrados = [];
    } else {
      _acopiosFiltrados = _acopios.where((a) =>
      a.productoNombre.toLowerCase().contains(query.toLowerCase()) ||
          a.productoCodigo.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  void limpiarFiltros() {
    _acopiosFiltrados = [];
    notifyListeners();
  }

  // --- REGISTRO DE MOVIMIENTOS ---
  Future<bool> registrarMovimiento({
    required String productoId,
    required String clienteId,
    required String proveedorId,
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final producto = await _productoRepo.obtenerPorCodigo(productoId);
      final cliente = await _clienteRepo.obtenerPorId(clienteId);
      final proveedor = _proveedores.firstWhere(
              (p) => p.codigo == proveedorId || p.id == proveedorId,
          orElse: () => ProveedorModel(codigo: proveedorId, nombre: 'Desconocido', tipo: TipoProveedor.proveedor, createdAt: DateTime.now())
      );

      if (producto == null || cliente == null) {
        throw Exception("Datos de producto o cliente no encontrados");
      }

      await _acopioRepo.registrarMovimiento(
        productoId: producto.codigo,
        clienteId: cliente.codigo,
        proveedorId: proveedor.codigo,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        valorizado: valorizado,
        // Datos desnormalizados
        productoNombre: producto.nombre,
        productoCodigo: producto.codigo,
        unidadBase: producto.unidadBase,
        categoriaNombre: producto.categoriaNombre ?? '',
        clienteNombre: cliente.razonSocial,
        proveedorNombre: proveedor.nombre,
      );

      await cargarTodo();
      return true;

    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoCodigo, String? clienteCodigo, String? proveedorCodigo
  }) async {
    return await _acopioRepo.obtenerHistorialAcopio(
        productoId: productoCodigo,
        clienteId: clienteCodigo,
        proveedorId: proveedorCodigo
    );
  }

  // --- PROVEEDORES ---
  Future<bool> crearProveedor(ProveedorModel proveedor) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.crear(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> actualizarProveedor(ProveedorModel proveedor) async {
    _isLoading = true; notifyListeners();
    try {
      await _proveedorRepo.actualizar(proveedor);
      await cargarProveedores();
      return true;
    } catch (e) { return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await _proveedorRepo.eliminar(id);
      _proveedores.removeWhere((p) => p.id == id || p.codigo == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }

  // --- TRASPASOS Y OTROS (Placeholders para evitar errores de compilación) ---
  Future<bool> registrarTraspaso({
    required String productoCodigo,
    required String origenClienteCodigo,
    required String origenProveedorCodigo,
    required String destinoClienteCodigo,
    required String destinoProveedorCodigo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
  }) async {
    // Implementar lógica de traspaso real aquí
    return true;
  }

  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async {
    return await _acopioRepo.obtenerFacturasUnicas();
  }

  Future<void> filtrarPorFactura(String factura) async {
    await _acopioRepo.filtrarPorFactura(factura);
  }
}