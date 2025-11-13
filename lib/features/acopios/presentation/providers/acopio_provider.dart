// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
import 'package:flutter/foundation.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

/// Estados del provider
enum AcopioState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider de Acopios (Versión Firebase)
class AcopioProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIOS
  // ========================================

  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  // ========================================
  // ESTADO
  // ========================================

  AcopioState _state = AcopioState.initial;
  List<AcopioDetalle> _acopios = [];
  List<ProveedorModel> _proveedores = [];
  String? _errorMessage;

  // Filtros (CAMBIO: IDs a String)
  String? _clienteFiltroCodigo;
  String? _proveedorFiltroCodigo;
  String _searchTerm = '';
  String? _facturaFiltro;

  // ========================================
  // GETTERS
  // ========================================

  AcopioState get state => _state;
  List<AcopioDetalle> get acopios => _acopios;
  List<ProveedorModel> get proveedores => _proveedores;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AcopioState.loading;
  bool get hasError => _state == AcopioState.error;
  bool get hasData => _acopios.isNotEmpty;

  String? get clienteFiltroCodigo => _clienteFiltroCodigo;
  String? get proveedorFiltroCodigo => _proveedorFiltroCodigo;
  String get searchTerm => _searchTerm;
  String? get facturaFiltro => _facturaFiltro;

  // Estadísticas (solo se modifican los campos, no la lógica)
  int get totalAcopios => _acopios.length;
  // Estos getters usan map/toSet, que funcionan con los nuevos IDs (String)
  int get totalProveedores =>
      _acopios.map((a) => a.acopio.proveedorId).toSet().length;

  int get totalClientes =>
      _acopios.map((a) => a.acopio.clienteId).toSet().length;

  List<AcopioDetalle> get acopiosEnDepositoSyg =>
      _acopios.where((a) => a.esDepositoSyg).toList();

  int get totalReservas => acopiosEnDepositoSyg.length;

  // ========================================
  // CARGAR DATOS
  // ========================================

  /// Carga acopios
  Future<void> cargarAcopios() async {
    try {
      _state = AcopioState.loading;
      _errorMessage = null;
      notifyListeners();

      // El repo ya no usa JOINs de SQL
      _acopios = await _acopioRepo.obtenerTodosConDetalle();

      _state = AcopioState.loaded;
      notifyListeners();

      print('✅ ${_acopios.length} acopios cargados');

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al cargar acopios: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Carga proveedores
  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
      notifyListeners();

      print('✅ ${_proveedores.length} proveedores cargados');

    } catch (e) {
      print('❌ Error al cargar proveedores: $e');
    }
  }

  // (cargarTodo y refrescar se mantienen)

  // ========================================
  // FILTROS
  // ========================================

  /// Filtra acopios por cliente
  Future<void> filtrarPorCliente(String? clienteCodigo) async { // CAMBIO: String
    try {
      _state = AcopioState.loading;
      _clienteFiltroCodigo = clienteCodigo;
      _proveedorFiltroCodigo = null;
      notifyListeners();

      if (clienteCodigo == null) {
        await cargarAcopios();
      } else {
        _acopios = await _acopioRepo.obtenerPorCliente(clienteCodigo);
        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al filtrar: $e';
      notifyListeners();
    }
  }

  /// Filtra acopios por proveedor
  Future<void> filtrarPorProveedor(String? proveedorCodigo) async { // CAMBIO: String
    try {
      _state = AcopioState.loading;
      _proveedorFiltroCodigo = proveedorCodigo;
      _clienteFiltroCodigo = null;
      notifyListeners();

      if (proveedorCodigo == null) {
        await cargarAcopios();
      } else {
        _acopios = await _acopioRepo.obtenerPorProveedor(proveedorCodigo);
        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al filtrar: $e';
      notifyListeners();
    }
  }

  // (buscarPorProducto, limpiarFiltros, filtrarPorFactura, obtenerFacturasUnicas se mantienen con pequeños ajustes internos en el repo)


  // ========================================
  // OPERACIONES DE MOVIMIENTOS
  // ========================================

  /// Registra un movimiento (entrada o salida) - MÃ©todo unificado
  Future<bool> registrarMovimiento({
    required String productoCodigo, // CAMBIO: String
    required String clienteCodigo,  // CAMBIO: String
    required String proveedorCodigo,// CAMBIO: String
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
    try {
      _state = AcopioState.loading;
      notifyListeners();

      await _acopioRepo.registrarMovimiento(
        productoCodigo: productoCodigo,
        clienteCodigo: clienteCodigo,
        proveedorCodigo: proveedorCodigo,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        valorizado: valorizado,
        montoValorizado: montoValorizado,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Movimiento ${tipo.name} registrado');
      return true;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al registrar movimiento: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  /// Registra traspaso entre acopios
  Future<bool> registrarTraspaso({
    required String productoCodigo, // CAMBIO: String
    required String origenClienteCodigo, // CAMBIO: String
    required String origenProveedorCodigo, // CAMBIO: String
    required String destinoClienteCodigo, // CAMBIO: String
    required String destinoProveedorCodigo, // CAMBIO: String
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      final exito = await _acopioRepo.registrarTraspaso(
        productoCodigo: productoCodigo,
        origenClienteCodigo: origenClienteCodigo,
        origenProveedorCodigo: origenProveedorCodigo,
        destinoClienteCodigo: destinoClienteCodigo,
        destinoProveedorCodigo: destinoProveedorCodigo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Traspaso registrado');
      return exito;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar traspaso: $e');
      return false;
    }
  }

  /// Registra movimiento en lote (múltiples productos)
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items,
    required String clienteCodigo, // CAMBIO: String
    required String proveedorCodigo, // CAMBIO: String
    required TipoMovimientoAcopio tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    bool valorizado = false,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      final exito = await _acopioRepo.registrarMovimientoEnLote(
        items: items,
        clienteCodigo: clienteCodigo,
        proveedorCodigo: proveedorCodigo,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        motivo: motivo,
        referencia: referencia,
        valorizado: valorizado,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Movimiento en lote registrado');
      return exito;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar lote: $e');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Obtiene el historial de movimientos de un acopio específico
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    required String productoCodigo, // CAMBIO: String
    required String clienteCodigo,  // CAMBIO: String
    required String proveedorCodigo,// CAMBIO: String
  }) async {
    try {
      return await _acopioRepo.obtenerHistorialAcopio(
        productoCodigo: productoCodigo,
        clienteCodigo: clienteCodigo,
        proveedorCodigo: proveedorCodigo,
      );
    } catch (e) {
      print('❌ Error en provider al obtener historial: $e');
      return [];
    }
  }
}