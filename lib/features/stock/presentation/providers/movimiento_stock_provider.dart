import 'package:flutter/foundation.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/repositories/movimiento_stock_repository.dart';

enum MovimientoStockState { initial, loading, loaded, error, registering }

class MovimientoStockProvider extends ChangeNotifier {
  final MovimientoStockRepository _repository = MovimientoStockRepository();

  MovimientoStockState _state = MovimientoStockState.initial;
  List<MovimientoStock> _movimientos = [];
  String? _errorMessage;

  TipoMovimiento? _tipoFiltro;
  String? _productoFiltroCodigo;

  MovimientoStockState get state => _state;
  List<MovimientoStock> get movimientos => _movimientos;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == MovimientoStockState.loading || _state == MovimientoStockState.registering;

  Future<void> cargarMovimientos({DateTime? desde, DateTime? hasta, TipoMovimiento? tipo}) async {
    _state = MovimientoStockState.loading;
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

  Future<void> cargarMovimientosDeProducto(String productoId, {TipoMovimiento? tipo}) async {
    _state = MovimientoStockState.loading;
    _productoFiltroCodigo = productoId;
    _tipoFiltro = tipo;
    notifyListeners();
    try {
      _movimientos = await _repository.obtenerMovimientos(
        productoId: productoId,
        tipo: tipo,
      );
      _state = MovimientoStockState.loaded;
    } catch (e) {
      _state = MovimientoStockState.error;
      print("Error cargando historial producto: $e");
    }
    notifyListeners();
  }

  Future<bool> registrarMovimiento({
    required String productoId,
    required String productoNombre,
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? usuarioId,
    // ✅ Parametros Obra
    String? obraId,
    String? obraNombre,
  }) async {
    if (_state == MovimientoStockState.registering) return false;

    try {
      _state = MovimientoStockState.registering;
      notifyListeners();

      await _repository.registrarMovimiento(
        productoId: productoId,
        productoNombre: productoNombre,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
        obraId: obraId,        // ✅ Pasar al repo
        obraNombre: obraNombre, // ✅ Pasar al repo
      );

      // Recargar lista si estamos viendo el detalle
      if (_productoFiltroCodigo != null) {
        await cargarMovimientosDeProducto(_productoFiltroCodigo!, tipo: _tipoFiltro);
      } else {
        await cargarMovimientos(tipo: _tipoFiltro);
      }

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