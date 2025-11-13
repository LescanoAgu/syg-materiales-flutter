// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/stock/presentation/providers/movimiento_stock_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/repositories/movimiento_stock_repository.dart';
// Importamos el repo de stock para validar
import '../../data/repositories/stock_repository.dart';

/// Estados posibles del provider
enum MovimientoStockState {
  initial,
  loading,
  loaded,
  error,
  registering,  // Cuando está registrando un movimiento
}

class MovimientoStockProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIO
  // ========================================

  final MovimientoStockRepository _repository = MovimientoStockRepository();
  // Agregamos el repo de Stock para validaciones previas
  final StockRepository _stockRepo = StockRepository();

  // ========================================
  // ESTADO
  // ========================================

  MovimientoStockState _state = MovimientoStockState.initial;
  List<MovimientoStock> _movimientos = [];
  String? _errorMessage;

  // Filtros actuales
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;
  String? _productoFiltroCodigo; // CAMBIO: de int? a String?

  // ========================================
  // GETTERS
  // ========================================

  MovimientoStockState get state => _state;
  List<MovimientoStock> get movimientos => _movimientos;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MovimientoStockState.loading;
  bool get isRegistering => _state == MovimientoStockState.registering;
  bool get hasError => _state == MovimientoStockState.error;
  bool get hasData => _movimientos.isNotEmpty;
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;
  TipoMovimiento? get tipoFiltro => _tipoFiltro;
  String? get productoFiltroCodigo => _productoFiltroCodigo;

  // Estadísticas
  int get totalMovimientos => _movimientos.length;
  int get totalEntradas =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.entrada)
          .length;
  int get totalSalidas =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.salida)
          .length;
  int get totalAjustes =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.ajuste)
          .length;

  // ========================================
  // OPERACIONES PRINCIPALES
  // ========================================

  /// Registra un nuevo movimiento de stock
  Future<bool> registrarMovimiento({
    required String productoId, // CAMBIO: int a String
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    int? usuarioId,
  }) async {
    try {
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      // Validación de Salida (opcional pero recomendada)
      if (tipo == TipoMovimiento.salida) {
        final stockActual = await _stockRepo.obtenerPorProductoCodigo(productoId);
        if (stockActual == null || stockActual.cantidadDisponible < cantidad) {
          throw Exception('Stock insuficiente. Disponible: ${stockActual?.cantidadDisponible ?? 0}');
        }
      }

      final movimiento = await _repository.registrarMovimiento(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
      );

      _movimientos.insert(0, movimiento);
      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento registrado: ${tipo.name} de $cantidad unidades');
      return true;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar movimiento: $e');
      return false;
    }
  }

  /// Carga los movimientos de un producto específico
  Future<void> cargarMovimientosDeProducto(String productoCodigo) async { // CAMBIO: int a String
    try {
      _state = MovimientoStockState.loading;
      _errorMessage = null;
      _productoFiltroCodigo = productoCodigo;
      notifyListeners();

      _movimientos = await _repository.getMovimientosPorProducto(productoCodigo);

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ ${_movimientos.length} movimientos cargados del producto $productoCodigo');
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cargar movimientos: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Carga movimientos con filtros opcionales
  Future<void> cargarMovimientos({
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
    int? limit,
  }) async {
    try {
      _state = MovimientoStockState.loading;
      _errorMessage = null;
      _fechaDesde = desde;
      _fechaHasta = hasta;
      _tipoFiltro = tipo;
      notifyListeners();

      _movimientos = await _repository.getMovimientos(
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        limit: limit,
      );

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ ${_movimientos.length} movimientos cargados con filtros');
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cargar movimientos: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Cancela un movimiento (crea un movimiento inverso)
  Future<bool> cancelarMovimiento(String movimientoId) async { // CAMBIO: int a String
    try {
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      final movimientoCancelacion = await _repository.cancelarMovimiento(movimientoId);
      _movimientos.insert(0, movimientoCancelacion);
      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento cancelado');
      return true;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cancelar movimiento: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  // ========================================
  // FILTROS
  // ========================================

  /// Limpia todos los filtros
  Future<void> limpiarFiltros() async {
    _fechaDesde = null;
    _fechaHasta = null;
    _tipoFiltro = null;
    _productoFiltroCodigo = null;
    await cargarMovimientos();
  }

  /// Refresca la vista actual
  Future<void> refrescar() async {
    if (_productoFiltroCodigo != null) {
      await cargarMovimientosDeProducto(_productoFiltroCodigo!);
    } else {
      await cargarMovimientos(
        desde: _fechaDesde,
        hasta: _fechaHasta,
        tipo: _tipoFiltro,
      );
    }
  }

  /// Registra movimiento en lote (múltiples productos)
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items, // items debe ser { 'productoId': String, 'cantidad': double }
    required TipoMovimiento tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    int? usuarioId,
  }) async {
    try {
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      // Validación previa de stock (solo para salidas)
      if (tipo == TipoMovimiento.salida) {
        for (var item in items) {
          final productoId = item['productoId'] as String;
          final cantidad = item['cantidad'] as double;
          final stockActual = await _stockRepo.obtenerPorProductoCodigo(productoId);
          if (stockActual == null || stockActual.cantidadDisponible < cantidad) {
            throw Exception('Stock insuficiente para $productoId. Disponible: ${stockActual?.cantidadDisponible ?? 0}');
          }
        }
      }

      final exito = await _repository.registrarMovimientoEnLote(
        items: items,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        valorizado: valorizado,
        usuarioId: usuarioId,
      );

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento en lote registrado');
      return exito;

    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al registrar lote: $e';
      notifyListeners();

      print('❌ Error: $e');
      return false;
    }
  }
}