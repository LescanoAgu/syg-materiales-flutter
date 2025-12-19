import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/orden_interna_model.dart';
import '../../data/models/remito_model.dart';
// ✅ IMPORT NUEVO: Necesario para la lógica de descuento
import '../../../acopios/data/models/acopio_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrdenInternaDetalle> _ordenes = [];
  OrdenInternaDetalle? _ordenSeleccionada;
  bool _isLoading = false;

  List<OrdenInternaDetalle> get ordenes => _ordenes;
  OrdenInternaDetalle? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;

  // --- CONSULTAS DE REMITOS ---
  Stream<List<Remito>> getRemitosPorCliente(String clienteId) {
    return _firestore
        .collection('remitos')
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Remito.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<Remito>> getRemitosPorProveedor(String proveedorId) {
    return _firestore
        .collection('remitos')
        .where('proveedorId', isEqualTo: proveedorId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Remito.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<Remito>> getRemitosPorOrden(String ordenId) {
    return _firestore
        .collection('remitos')
        .where('ordenId', isEqualTo: ordenId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Remito.fromMap(doc.data(), doc.id))
        .toList());
  }

  // --- CARGA DE ÓRDENES ---
  Future<void> cargarOrdenes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('ordenes_internas')
          .orderBy('createdAt', descending: true)
          .get();

      List<OrdenInternaDetalle> temp = [];

      for (var doc in snapshot.docs) {
        final ordenModelo = OrdenInternaModel.fromSnapshot(doc);
        final data = doc.data();
        String clienteNombre = data['clienteRazonSocial'] ?? 'Cliente';
        String obraNombre = data['obraNombre'] ?? 'Obra';

        temp.add(OrdenInternaDetalle(
            orden: ordenModelo,
            clienteRazonSocial: clienteNombre,
            obraNombre: obraNombre
        ));
      }
      _ordenes = temp;

    } catch (e) {
      print("Error cargando órdenes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalleOrden(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _firestore.collection('ordenes_internas').doc(id).get();
      if (!doc.exists) {
        _ordenSeleccionada = null;
        return;
      }

      final ordenModelo = OrdenInternaModel.fromSnapshot(doc);
      final data = doc.data() as Map<String, dynamic>;

      _ordenSeleccionada = OrdenInternaDetalle(
          orden: ordenModelo,
          clienteRazonSocial: data['clienteRazonSocial'] ?? 'Cliente',
          obraNombre: data['obraNombre'] ?? 'Obra'
      );
    } catch (e) {
      print("Error detalle: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CREAR Y ACTUALIZAR ---
  Future<bool> aprobarOrden({
    required String ordenId,
    required String usuarioId,
    required List<OrdenItemDetalle> itemsModificados,
    String? observaciones,
    String? proveedor,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final itemsMap = itemsModificados.map((i) => i.toMap()).toList();

      await _firestore.collection('ordenes_internas').doc(ordenId).update({
        'estado': 'aprobada',
        'items': itemsMap,
        'aprobadoPor': usuarioId,
        'fechaAprobacion': Timestamp.now(),
        'observacionesAprobacion': observaciones,
        'proveedor': proveedor, // Campo legacy (visual)
        'modificadoPor': usuarioId,
      });

      await cargarOrdenes();
      if (_ordenSeleccionada?.orden.id == ordenId) {
        await cargarDetalleOrden(ordenId);
      }
      return true;
    } catch (e) {
      print("Error aprobando: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? titulo,
    required List<Map<String, dynamic>> items,
    String? observaciones,
    required String prioridad,
    bool esRetiroAcopio = false,
    String? acopioId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      String clienteNombre = '';
      String obraNombre = '';
      try {
        final cd = await _firestore.collection('clientes').doc(clienteId).get();
        if(cd.exists) clienteNombre = cd.data()?['razonSocial'] ?? '';
      } catch(_) {}
      try {
        final od = await _firestore.collection('obras').doc(obraId).get();
        if (od.exists) obraNombre = od.data()?['nombre'] ?? '';
      } catch(_) {}

      final ordenId = const Uuid().v4();
      final numero = "OI-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      List<Map<String, dynamic>> itemsParaGuardar = items.map((i) {
        return {
          'productoId': i['productoId'],
          'productoNombre': i['productoNombre'],
          'productoCodigo': i['productoCodigo'],
          'unidad': i['unidad'],
          'cantidad': i['cantidad'],
          'cantidadEntregada': 0,
        };
      }).toList();

      final nuevaOrden = {
        'id': ordenId,
        'numero': numero,
        'clienteId': clienteId,
        'clienteRazonSocial': clienteNombre,
        'obraId': obraId,
        'obraNombre': obraNombre,
        'solicitanteId': '',
        'solicitanteNombre': solicitanteNombre,
        'fechaPedido': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'estado': 'solicitado',
        'prioridad': prioridad,
        'titulo': titulo,
        'items': itemsParaGuardar,
        'observacionesCliente': observaciones,
        'esRetiroAcopio': esRetiroAcopio,
        'acopioId': acopioId,
        'origen': esRetiroAcopio ? 'acopio_cliente' : 'stock_propio',
      };

      await _firestore.collection('ordenes_internas').doc(ordenId).set(nuevaOrden);
      await cargarOrdenes();
      return true;
    } catch (e) {
      print("Error creating order: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generarRemito({
    required OrdenInternaDetalle ordenDetalle,
    required List<Map<String, dynamic>> itemsAEntregar,
    required Uint8List firmaAutoriza,
    required Uint8List firmaRecibe,
    required String usuarioId,
    required String usuarioNombre,
    String? proveedorId,
    String? proveedorNombre,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final remitoId = const Uuid().v4();
      final numeroRemito = "REM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

      // 1. Armar Items
      List<RemitoItem> itemsRemito = [];
      for (var itemEntrega in itemsAEntregar) {
        String pId = itemEntrega['productoId'];
        double cantidadEntrega = (itemEntrega['cantidad'] as num).toDouble();

        final itemOriginal = ordenDetalle.items.firstWhere(
                (i) => i.materialId == pId || i.productoCodigo == pId,
            orElse: () => ordenDetalle.items.first
        );

        itemsRemito.add(RemitoItem(
            productoId: pId,
            productoNombre: itemOriginal.nombreMaterial,
            productoCodigo: itemOriginal.productoCodigo,
            cantidad: cantidadEntrega,
            cantidadSolicitadaTotal: itemOriginal.cantidad.toDouble(),
            saldoPendienteAnterior: (itemOriginal.cantidad - itemOriginal.cantidadEntregada).toDouble(),
            unidad: itemOriginal.unidadBase
        ));
      }

      final nuevoRemito = Remito(
        id: remitoId,
        numeroRemito: numeroRemito,
        ordenId: ordenDetalle.orden.id!,
        fecha: DateTime.now(),
        clienteId: ordenDetalle.orden.clienteId,
        obraId: ordenDetalle.orden.obraId,
        proveedorId: proveedorId,
        proveedorNombre: proveedorNombre,
        items: itemsRemito,
        firmaAutorizoUrl: '',
        firmaRecibioUrl: '',
        usuarioDespachadorId: usuarioId,
        usuarioDespachadorNombre: usuarioNombre,
      );

      final batch = _firestore.batch();
      final remitoRef = _firestore.collection('remitos').doc(remitoId);
      batch.set(remitoRef, nuevoRemito.toMap());

      final ordenRef = _firestore.collection('ordenes_internas').doc(ordenDetalle.orden.id);

      // 2. Lógica de Descuento (Acopio vs Stock)
      // Buscamos acopio si corresponde
      AcopioModel? acopioData;
      DocumentReference? acopioRef;

      if (ordenDetalle.orden.origen == OrigenAbastecimiento.acopio_cliente && ordenDetalle.orden.acopioId != null) {
        acopioRef = _firestore.collection('acopios').doc(ordenDetalle.orden.acopioId);
        final snap = await acopioRef.get();
        if(snap.exists) acopioData = AcopioModel.fromSnapshot(snap);
      }

      List<Map<String, dynamic>> itemsOrdenActualizados = ordenDetalle.items.map((itemOrig) {
        final itemEntrega = itemsAEntregar.firstWhere(
                (i) => i['productoId'] == itemOrig.materialId || i['productoId'] == itemOrig.productoCodigo,
            orElse: () => {}
        );

        double entregadoAhora = 0;
        if (itemEntrega.isNotEmpty) {
          entregadoAhora = (itemEntrega['cantidad'] as num).toDouble();

          // A. Descuento de Acopio
          if (acopioData != null && acopioRef != null) {
            final idx = acopioData!.items.indexWhere((ai) => ai.productoId == itemOrig.materialId);
            if (idx != -1) {
              // Actualizamos objeto local para guardar después
              final itemAcopio = acopioData!.items[idx];
              final nuevosItems = List<AcopioItem>.from(acopioData!.items);
              nuevosItems[idx] = itemAcopio.copyWith(cantidadDisponible: itemAcopio.cantidadDisponible - entregadoAhora);

              acopioData = AcopioModel(
                id: acopioData!.id,
                clienteId: acopioData!.clienteId,
                clienteRazonSocial: acopioData!.clienteRazonSocial,
                proveedorId: acopioData!.proveedorId,
                proveedorNombre: acopioData!.proveedorNombre,
                fechaUltimoMovimiento: DateTime.now(),
                items: nuevosItems,
              );
            }
          }
          // B. Descuento de Stock Físico (Solo si es despacho propio y origen stock)
          else if (ordenDetalle.orden.origen == OrigenAbastecimiento.stock_propio && proveedorId == null) {
            final prodRef = _firestore.collection('productos').doc(itemOrig.materialId);
            batch.update(prodRef, {'cantidadDisponible': FieldValue.increment(-entregadoAhora)});
          }
        }

        final nuevoItem = itemOrig.copyWith(
            cantidadEntregada: itemOrig.cantidadEntregada + entregadoAhora.toInt()
        );
        return nuevoItem.toMap();
      }).toList();

      if (acopioData != null && acopioRef != null) {
        batch.update(acopioRef!, acopioData!.toMap());
      }

      bool ordenCompleta = itemsOrdenActualizados.every((i) {
        return (i['cantidadEntregada'] as int) >= (i['cantidad'] as int);
      });

      batch.update(ordenRef, {
        'items': itemsOrdenActualizados,
        'estado': ordenCompleta ? 'entregado' : 'en_proceso'
      });

      await batch.commit();
      await cargarOrdenes();
      return true;

    } catch(e) {
      print("Error generando remito: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}