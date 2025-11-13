// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
import 'package:flutter/material.dart';
import '../../data/repositories/orden_interna_repository.dart'; // Importar el repo migrado
import '../../data/models/orden_interna_model.dart'; // Si tienes este modelo lo debes usar para la lista

/// Provider de Órdenes Internas (Versión Firebase)
class OrdenInternaProvider extends ChangeNotifier {
  // Asumimos que OrdenInternaRepository ya fue migrado
  final OrdenInternaRepository _repository = OrdenInternaRepository();

  // Estado
  // CAMBIO: Almacenamos el modelo OrdenInternaDetalle, no un Map de rawQuery
  List<OrdenInternaDetalle> _ordenesDetalle = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<OrdenInternaDetalle> get ordenes => _ordenesDetalle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _ordenesDetalle.isNotEmpty;
  bool get hasError => _errorMessage != null;

  // ========================================
  // CARGAR ÓRDENES
  // ========================================

  Future<void> cargarOrdenes({String? estado}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usamos el repo migrado (que devuelve OrdenInternaDetalle)
      _ordenesDetalle = await _repository.getOrdenes(estado: estado);

      print('✅ ${_ordenesDetalle.length} órdenes cargadas');
    } catch (e) {
      _errorMessage = 'Error: $e';
      print('❌ $_errorMessage');
      _ordenesDetalle = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() => cargarOrdenes();

  // ========================================
  // CREAR ORDEN
  // ========================================

  Future<bool> crearOrden({
    required String clienteCodigo, // CAMBIO: String
    required String obraCodigo,    // CAMBIO: String
    required String solicitanteNombre,
    List<Map<String, dynamic>>? items,
    DateTime? fechaSolicitud,
    String? prioridad, // Este campo no está en el modelo, pero se puede omitir o agregar a observaciones
    String? observaciones,
    int? usuarioId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Llamamos al repositorio migrado
      await _repository.crearOrden(
        clienteCodigo: clienteCodigo,
        obraCodigo: obraCodigo,
        solicitanteNombre: solicitanteNombre,
        items: items ?? [],
        observacionesCliente: observaciones,
        usuarioCreadorId: usuarioId,
      );

      await cargarOrdenes();
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error: $e';
      notifyListeners();
      print('❌ $_errorMessage');
      return false;
    }
  }

  // ========================================
  // APROBAR/RECHAZAR/CANCELAR
  // ========================================

  Future<bool> aprobarOrden(
      String ordenId, { // CAMBIO: String
        int? aprobadoPorUsuarioId,
        String? observacionesInternas,
      }) async {
    try {
      final exito = await _repository.aprobarOrden(
        ordenId: ordenId,
        aprobadoPorUsuarioId: aprobadoPorUsuarioId ?? 1,
        observacionesInternas: observacionesInternas,
      );
      await cargarOrdenes();
      return exito;
    } catch (e) {
      _errorMessage = 'Error al aprobar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazarOrden(
      String ordenId, { // CAMBIO: String
        int? rechazadoPorUsuarioId,
        required String motivoRechazo,
      }) async {
    try {
      final exito = await _repository.rechazarOrden(
        ordenId: ordenId,
        rechazadoPorUsuarioId: rechazadoPorUsuarioId ?? 1,
        motivoRechazo: motivoRechazo,
      );
      await cargarOrdenes();
      return exito;
    } catch (e) {
      _errorMessage = 'Error al rechazar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarOrden(String ordenId, {String? motivo}) async { // CAMBIO: String
    try {
      final exito = await _repository.cancelarOrden(ordenId: ordenId);
      await cargarOrdenes();
      return exito;
    } catch (e) {
      _errorMessage = 'Error al cancelar: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // CAMBIAR ESTADO
  // ========================================

  Future<bool> cambiarEstado({
    required String ordenId, // CAMBIO: String
    required String nuevoEstado,
    String? observaciones,
    int? usuarioId,
  }) async {
    try {
      final exito = await _repository.cambiarEstado(
        ordenId: ordenId,
        nuevoEstado: nuevoEstado,
      );
      await cargarOrdenes();
      return exito;
    } catch (e) {
      _errorMessage = 'Error al cambiar estado: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // FILTROS (se usa el filtro del repositorio)
  // ========================================

  Future<void> filtrarPorEstado(String? estado) async {
    await cargarOrdenes(estado: estado);
  }

  // ========================================
  // ESTADÍSTICAS (Ahora usan el repositorio)
  // ========================================

  // Se tiene que leer el estado desde los modelos cargados localmente
  int contarPorEstado(String estado) {
    return _ordenesDetalle.where((o) => o.orden.estado == estado).length;
  }

  int get totalOrdenes => _ordenesDetalle.length;
  // Estos getters se basan en el conteo de la lista local
  int get ordenesSolicitadas => contarPorEstado('solicitado');
  int get ordenesEnPreparacion => contarPorEstado('en_preparacion');
  int get ordenesDespachadas => contarPorEstado('despachado');
}