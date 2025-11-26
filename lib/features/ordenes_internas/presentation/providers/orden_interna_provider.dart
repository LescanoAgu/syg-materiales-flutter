import 'package:flutter/material.dart';
import '../../data/repositories/orden_interna_repository.dart';
import '../../data/models/orden_interna_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final OrdenInternaRepository _repository = OrdenInternaRepository();

  List<OrdenInternaDetalle> _ordenesDetalle = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrdenInternaDetalle> get ordenes => _ordenesDetalle;
  bool get isLoading => _isLoading;
  bool get hasData => _ordenesDetalle.isNotEmpty;
  String? get errorMessage => _errorMessage;

  // Estadísticas simples
  int get ordenesSolicitadas => _ordenesDetalle.where((o) => o.orden.estado == 'solicitado').length;

  Future<void> cargarOrdenes({String? estado}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _ordenesDetalle = await _repository.getOrdenes(estado: estado);
    } catch (e) {
      _errorMessage = e.toString();
      _ordenesDetalle = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FIX 1: MÉTODO FALTANTE (Para cargar los items 'on-demand')
  /// Obtiene el detalle completo de una orden (incluyendo sus items)
  Future<OrdenInternaDetalle?> cargarDetalleOrden(String ordenId) async {
    try {
      return await _repository.getOrdenPorId(ordenId);
    } catch (e) {
      print("Error cargando detalle: $e");
      return null;
    }
  }

  Future<bool> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    required List<Map<String, dynamic>> items, // Lista de productos
    String? observaciones,
    DateTime? fechaSolicitud,
    String? prioridad,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      String obsFinal = observaciones ?? '';
      if (prioridad != null && prioridad.isNotEmpty) {
        obsFinal = "[${prioridad.toUpperCase()}] $obsFinal".trim();
      }

      await _repository.crearOrden(
        clienteId: clienteId,
        obraId: obraId,
        solicitanteNombre: solicitanteNombre,
        items: items,
        observacionesCliente: obsFinal,
      );

      await cargarOrdenes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstado({required String ordenId, required String nuevoEstado}) async {
    try {
      await _repository.cambiarEstado(ordenId: ordenId, nuevoEstado: nuevoEstado);
      await cargarOrdenes();
      return true;
    } catch (e) { return false; }
  }

  // Métodos para aprobar/rechazar/cancelar
  Future<bool> aprobarOrden(String id, {int? aprobadoPorUsuarioId, String? observacionesInternas}) async =>
      cambiarEstado(ordenId: id, nuevoEstado: 'aprobado');

  Future<bool> rechazarOrden(String id, {int? rechazadoPorUsuarioId, required String motivoRechazo}) async =>
      cambiarEstado(ordenId: id, nuevoEstado: 'rechazado');

  Future<bool> cancelarOrden(String id) async =>
      cambiarEstado(ordenId: id, nuevoEstado: 'cancelado');
}