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
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  // Estadísticas
  int get ordenesSolicitadas => _ordenesDetalle.where((o) => o.orden.estado == 'solicitado').length;
  int get ordenesEnPreparacion => _ordenesDetalle.where((o) => o.orden.estado == 'en_preparacion').length;
  int get ordenesDespachadas => _ordenesDetalle.where((o) => o.orden.estado == 'despachado').length;

  Future<void> cargarOrdenes({String? estado}) async {
    _isLoading = true;
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

  Future<void> refrescar() => cargarOrdenes();

  Future<void> filtrarPorEstado(String? estado) async => cargarOrdenes(estado: estado);

  // Corrección: Aceptar parámetros extra y opcionales
  Future<bool> crearOrden({
    required String clienteCodigo, // Usamos código como ID
    required String obraCodigo,
    required String solicitanteNombre,
    List<Map<String, dynamic>>? items,
    String? observaciones,
    // Parámetros extra que pide la UI
    DateTime? fechaSolicitud,
    String? prioridad,
    int? usuarioId, // Legacy, ignorar o usar
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      String obsFinal = observaciones ?? '';
      if (prioridad != null) obsFinal += '\nPrioridad: $prioridad';

      await _repository.crearOrden(
        clienteId: clienteCodigo,
        obraId: obraCodigo,
        solicitanteNombre: solicitanteNombre,
        items: items ?? [],
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

  Future<bool> cambiarEstado({
    required String ordenId,
    required String nuevoEstado
  }) async {
    try {
      await _repository.cambiarEstado(ordenId: ordenId, nuevoEstado: nuevoEstado);
      await cargarOrdenes();
      return true;
    } catch (e) { return false; }
  }

  // Métodos faltantes para evitar errores de compilación
  Future<bool> aprobarOrden(String ordenId, {int? aprobadoPorUsuarioId, String? observacionesInternas}) async {
    return cambiarEstado(ordenId: ordenId, nuevoEstado: 'aprobado');
  }

  Future<bool> rechazarOrden(String ordenId, {int? rechazadoPorUsuarioId, required String motivoRechazo}) async {
    return cambiarEstado(ordenId: ordenId, nuevoEstado: 'rechazado');
  }

  Future<bool> cancelarOrden(String ordenId) async {
    return cambiarEstado(ordenId: ordenId, nuevoEstado: 'cancelado');
  }
}