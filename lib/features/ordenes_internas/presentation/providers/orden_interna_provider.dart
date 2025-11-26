import 'package:flutter/material.dart';
import '../../data/repositories/orden_interna_repository.dart';
import '../../data/models/orden_interna_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final OrdenInternaRepository _repository = OrdenInternaRepository();
  List<OrdenInternaDetalle> _ordenes = [];
  bool _isLoading = false;

  List<OrdenInternaDetalle> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  bool get hasData => _ordenes.isNotEmpty;

  Future<void> cargarOrdenes() async {
    _isLoading = true; notifyListeners();
    try { _ordenes = await _repository.getOrdenes(); } catch (_) {}
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<OrdenInternaDetalle?> cargarDetalleOrden(String id) async {
    return await _repository.getOrdenPorId(id);
  }

  Future<bool> crearOrden({
    required String clienteId, required String obraId,
    required String solicitanteNombre, required List<Map<String, dynamic>> items,
    String? observaciones, DateTime? fechaSolicitud, String? prioridad
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.crearOrden(
          clienteId: clienteId, obraId: obraId, solicitanteNombre: solicitanteNombre,
          items: items, observacionesCliente: observaciones
      );
      await cargarOrdenes(); return true;
    } catch (e) { return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  // ✅ NUEVO: Eliminar
  Future<bool> eliminarOrden(String id) async {
    try {
      await _repository.eliminar(id);
      _ordenes.removeWhere((o) => o.orden.id == id);
      notifyListeners();
      return true;
    } catch (e) { return false; }
  }
}