import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../data/repositories/orden_interna_repository.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../../data/models/remito_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final OrdenInternaRepository _repository = OrdenInternaRepository();

  List<OrdenInternaDetalle> _ordenes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OrdenInternaDetalle> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarOrdenes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _ordenes = await _repository.getOrdenes();
      _ordenes.sort((a, b) {
        if (a.orden.prioridad == 'urgente' && b.orden.prioridad != 'urgente') return -1;
        if (a.orden.prioridad != 'urgente' && b.orden.prioridad == 'urgente') return 1;
        return b.orden.createdAt.compareTo(a.orden.createdAt);
      });
    } catch (e) {
      _errorMessage = "Error cargando órdenes: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Remito>> cargarRemitos(String ordenId) async {
    try {
      return await _repository.obtenerRemitos(ordenId);
    } catch (e) {
      return [];
    }
  }

  Future<OrdenInternaDetalle?> cargarDetalleOrden(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _repository.getOrdenPorId(id);
    } catch (e) {
      _errorMessage = "Error cargando detalle: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ CREAR CON TÍTULO
  Future<bool> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? titulo, // ✅ AGREGADO
    required List<Map<String, dynamic>> items,
    String? observaciones,
    String prioridad = 'media',
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.crearOrden(
          clienteId: clienteId,
          obraId: obraId,
          solicitanteNombre: solicitanteNombre,
          titulo: titulo, // ✅
          items: items,
          observacionesCliente: observaciones,
          prioridad: prioridad
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

  // ✅ EDITAR CON TÍTULO
  Future<bool> editarOrden({
    required String ordenId,
    required String clienteId,
    required String obraId,
    required String prioridad,
    String? titulo, // ✅ AGREGADO
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.editarOrden(
        ordenId: ordenId,
        clienteId: clienteId,
        obraId: obraId,
        titulo: titulo, // ✅
        prioridad: prioridad,
        observaciones: observaciones,
        items: items,
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

  Future<bool> aprobarOrden({
    required String ordenId,
    required List<OrdenItem> itemsOriginales,
    required Map<String, Map<String, dynamic>> logistica,
    required String usuarioId,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      List<OrdenItem> itemsConfigurados = [];
      for (var item in itemsOriginales) {
        final config = logistica[item.id];
        if (config != null) {
          itemsConfigurados.add(item.copyWith(
            origen: config['origen'],
            proveedorId: config['proveedorId'],
            cantidadAprobada: item.cantidadSolicitada,
          ));
        } else {
          itemsConfigurados.add(item);
        }
      }
      await _repository.aprobarOrdenConLogistica(
        ordenId: ordenId,
        itemsConfigurados: itemsConfigurados,
        usuarioAprobadorId: usuarioId,
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

  Future<bool> generarRemito({
    required String ordenId,
    required List<Map<String, dynamic>> items,
    required Uint8List firmaAutoriza,
    required Uint8List firmaRecibe,
    required String usuarioId,
    required String usuarioNombre,
  }) async {
    _isLoading = true; notifyListeners();
    try {
      await _repository.generarRemito(
        ordenId: ordenId,
        itemsDespachados: items,
        firmaAutoriza: firmaAutoriza,
        firmaRecibe: firmaRecibe,
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
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

  Future<bool> asignarResponsable(String ordenId, String uid, String nombre) async {
    try {
      await _repository.asignarResponsable(ordenId, uid, nombre);
      await cargarOrdenes();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> agregarEtiqueta(String ordenId, String uid) async {
    try {
      await _repository.etiquetarUsuario(ordenId, uid);
      return true;
    } catch (e) { return false; }
  }

  Future<bool> confirmarEntrega(String ordenId, Uint8List firma) async => false;
  Future<bool> registrarDespacho({required String ordenId, required String ordenNumero, required String obraId, required String usuarioId, required String usuarioNombre, required List<Map<String, dynamic>> items}) async => false;
}