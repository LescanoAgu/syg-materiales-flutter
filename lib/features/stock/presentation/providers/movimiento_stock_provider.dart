import 'package:flutter/foundation.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/repositories/movimiento_stock_repository.dart';

enum MovimientoStockState { initial, loading, loaded, error, registering }

class MovimientoStockProvider extends ChangeNotifier {
  final MovimientoStockRepository _repository = MovimientoStockRepository();

  MovimientoStockState _state = MovimientoStockState.initial;
  List<MovimientoStock> _movimientos = [];
  String? _errorMessage;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;
  String? _productoFiltroCodigo; // CAMBIO: String

  MovimientoStockState get state => _state;
  List<MovimientoStock> get movimientos => _movimientos;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MovimientoStockState.loading;

  Future<void> cargarMovimientos({DateTime? desde, DateTime? hasta, TipoMovimiento? tipo}) async {
    _state = MovimientoStockState.loading;
    _fechaDesde = desde;
    _fechaHasta = hasta;
    _tipoFiltro = tipo;
    _productoFiltroCodigo = null;
    notifyListeners();

    try {
      _movimientos = await _repository.obtenerMovimientos(
        desde: desde,
        hasta: hasta,
        tipo: tipo,
      );
      _state = MovimientoStockState.loaded;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> cargarMovimientosDeProducto(String productoId) async {
    _state = MovimientoStockState.loading;
    _productoFiltroCodigo = productoId;
    notifyListeners();
    try {
      _movimientos = await _repository.obtenerMovimientos(productoId: productoId);
      _state = MovimientoStockState.loaded;
    } catch (e) {
      _state = MovimientoStockState.error;
    }
    notifyListeners();
  }

  Future<bool> registrarMovimiento({
    required String productoId, // CAMBIO: String
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? usuarioId,
  }) async {
    try {
      _state = MovimientoStockState.registering;
      notifyListeners();

      await _repository.registrarMovimiento(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
      );

      _state = MovimientoStockState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}