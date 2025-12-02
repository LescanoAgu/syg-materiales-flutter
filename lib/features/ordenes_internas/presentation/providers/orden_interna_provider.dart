import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../data/repositories/orden_interna_repository.dart';
import '../../data/models/orden_interna_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final OrdenInternaRepository _repository = OrdenInternaRepository();

  List<OrdenInternaDetalle> _ordenes = [];
  List<OrdenInternaDetalle> _misDespachos = []; // ✅ NUEVO

  bool _isLoading = false;
  String? _errorMessage;

  List<OrdenInternaDetalle> get ordenes => _ordenes;
  List<OrdenInternaDetalle> get misDespachos => _misDespachos; // ✅ NUEVO
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() => _errorMessage = null;

  Future<void> cargarOrdenes() async {
    _isLoading = true; notifyListeners();
    try {
      _ordenes = await _repository.getOrdenes();
      _ordenes.sort((a, b) {
        if (a.orden.prioridad == 'urgente' && b.orden.prioridad != 'urgente') return -1;
        return 0;
      });
    } catch (_) {}
    finally { _isLoading = false; notifyListeners(); }
  }

  // ✅ NUEVO: Cargar mis despachos
  Future<void> cargarMisDespachos(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _misDespachos = await _repository.getMisDespachos(userId);
    } catch (e) {
      print("Error cargando mis despachos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrdenInternaDetalle?> cargarDetalleOrden(String id) async {
    return await _repository.getOrdenPorId(id);
  }

  Future<bool> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    required List<Map<String, dynamic>> items,
    String? observaciones,
    String prioridad = 'media',
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.crearOrden(
          clienteId: clienteId, obraId: obraId, solicitanteNombre: solicitanteNombre,
          items: items, observacionesCliente: observaciones, prioridad: prioridad
      );
      await cargarOrdenes(); return true;
    } catch (e) { return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> aprobarOrden({
    required String ordenId,
    required Map<String, String> configuracionItems,
    String? proveedorId,
    required String usuarioId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.aprobarOrden(
        ordenId: ordenId,
        configuracionItems: configuracionItems,
        proveedorId: proveedorId,
        usuarioAprobadorId: usuarioId,
      );
      await cargarOrdenes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> registrarDespacho({
    required String ordenId,
    required String ordenNumero,
    required String obraId,
    required String usuarioId,
    required String usuarioNombre,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registrarDespacho(
        ordenId: ordenId, ordenNumero: ordenNumero, obraId: obraId,
        usuarioId: usuarioId, usuarioNombre: usuarioNombre, itemsDespachados: items,
      );
      await cargarOrdenes();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      return false;
    } finally { _isLoading = false; notifyListeners(); }
  }

  Future<bool> asignarResponsable({
    required String ordenId,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.asignarResponsable(ordenId, usuarioId, usuarioNombre);
      await cargarOrdenes(); return true;
    } catch (e) { return false; }
    finally { _isLoading = false; notifyListeners(); }
  }

  // ✅ NUEVO: Etiquetar usuario
  Future<bool> agregarEtiqueta(String ordenId, String userId) async {
    try {
      await _repository.etiquetarUsuario(ordenId, userId);
      return true;
    } catch (e) { return false; }
  }

  // ✅ NUEVO: Confirmar entrega con firma
  Future<bool> confirmarEntrega(String ordenId, Uint8List firmaBytes) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.finalizarEntregaConFirma(ordenId: ordenId, firmaBytes: firmaBytes);
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

  Future<bool> eliminarOrden(String id) async {
    try {
      await _repository.eliminar(id);
      _ordenes.removeWhere((o) => o.orden.id == id);
      notifyListeners(); return true;
    } catch (e) { return false; }
  }
}