import 'package:flutter/foundation.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

enum AcopioState { initial, loading, loaded, error }

class AcopioProvider extends ChangeNotifier {
  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  List<AcopioDetalle> _acopios = [];
  List<ProveedorModel> _proveedores = [];

  List<AcopioDetalle> get acopios => _acopios;
  List<ProveedorModel> get proveedores => _proveedores;

  int get totalAcopios => _acopios.length;
  int get totalClientes => _acopios.map((a) => a.clienteRazonSocial).toSet().length;
  int get totalProveedores => _acopios.map((a) => a.proveedorNombre).toSet().length;
  int get totalReservas => _acopios.where((a) => a.esDepositoSyg).length;
  List<AcopioDetalle> get acopiosEnDepositoSyg => _acopios.where((a) => a.esDepositoSyg).toList();

  bool get isLoading => _acopios.isEmpty; // Simplificación
  bool get hasData => _acopios.isNotEmpty;
  bool get hasError => false;
  String? get errorMessage => null;

  Future<void> cargarTodo() async {
    await Future.wait([cargarAcopios(), cargarProveedores()]);
  }

  Future<void> refrescar() => cargarTodo();

  Future<void> cargarAcopios() async {
    _acopios = await _acopioRepo.obtenerTodosConDetalle();
    notifyListeners();
  }

  Future<void> cargarProveedores() async {
    _proveedores = await _proveedorRepo.obtenerTodos();
    notifyListeners();
  }

  // MÉTODOS DE AGRUPACIÓN QUE FALTABAN
  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorCliente() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in _acopios) {
      map.putIfAbsent(a.clienteRazonSocial, () => []).add(a);
    }
    return map;
  }

  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorProveedor() {
    var map = <String, List<AcopioDetalle>>{};
    for (var a in _acopios) {
      map.putIfAbsent(a.proveedorNombre, () => []).add(a);
    }
    return map;
  }

  // MÉTODO DE HISTORIAL QUE FALTABA
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    String? productoCodigo, String? clienteCodigo, String? proveedorCodigo
  }) async {
    return await _acopioRepo.obtenerHistorialAcopio(
        productoId: productoCodigo,
        clienteId: clienteCodigo,
        proveedorId: proveedorCodigo
    );
  }

  // Filtros (Placeholders para evitar error)
  void buscarPorProducto(String t) {}
  void limpiarFiltros() {}
  Future<void> filtrarPorFactura(String f) async {}
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async => [];

  // Traspaso (Corrección de argumentos)
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
    // Implementación simulada
    return true;
  }

  // Registro movimiento simple
  Future<bool> registrarMovimiento({
    required String productoId, // OJO: puede llamarse productoCodigo en UI
    required String clienteId,
    required String proveedorId,
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
    double? montoValorizado,
  }) async {
    // Implementación simulada
    return true;
  }
}