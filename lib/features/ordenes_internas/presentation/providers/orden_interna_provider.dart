import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/orden_interna_model.dart';
import '../../data/models/remito_model.dart';
import '../../../acopios/data/models/acopio_model.dart';

class OrdenInternaProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrdenInternaDetalle> _ordenes = [];
  OrdenInternaDetalle? _ordenSeleccionada;
  bool _isLoading = false;

  List<OrdenInternaDetalle> get ordenes => _ordenes;
  OrdenInternaDetalle? get ordenSeleccionada => _ordenSeleccionada;
  bool get isLoading => _isLoading;

  // --- STREAMS ---
  Stream<List<Remito>> getRemitosPorCliente(String clienteId) {
    return _firestore.collection('remitos').where('clienteId', isEqualTo: clienteId).orderBy('fecha', descending: true).snapshots().map((s) => s.docs.map((d) => Remito.fromMap(d.data(), d.id)).toList());
  }
  Stream<List<Remito>> getRemitosPorProveedor(String proveedorId) {
    return _firestore.collection('remitos').where('proveedorId', isEqualTo: proveedorId).orderBy('fecha', descending: true).snapshots().map((s) => s.docs.map((d) => Remito.fromMap(d.data(), d.id)).toList());
  }
  Stream<List<Remito>> getRemitosPorOrden(String ordenId) {
    return _firestore.collection('remitos').where('ordenId', isEqualTo: ordenId).orderBy('fecha', descending: true).snapshots().map((s) => s.docs.map((d) => Remito.fromMap(d.data(), d.id)).toList());
  }

  // --- CARGA DE ÓRDENES (Auto-Reparación con ALIAS) ---
  Future<void> cargarOrdenes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('ordenes_internas')
          .orderBy('createdAt', descending: true)
          .get();

      List<OrdenInternaDetalle> temp = [];
      // Cache para optimizar lecturas repetidas
      Map<String, String> cacheClientes = {};
      Map<String, String> cacheObras = {};

      for (var doc in snapshot.docs) {
        final ordenModelo = OrdenInternaModel.fromSnapshot(doc);
        final data = doc.data();

        String clienteNombre = data['clienteRazonSocial'] ?? '';
        String obraNombre = data['obraNombre'] ?? '';
        bool necesitaUpdate = false;

        // 1. RECUPERAR CLIENTE (Prioridad: Razón Social -> Nombre -> Alias)
        if (clienteNombre.isEmpty || clienteNombre.contains('Eliminado') || clienteNombre.contains('ID:')) {
          if (cacheClientes.containsKey(ordenModelo.clienteId)) {
            clienteNombre = cacheClientes[ordenModelo.clienteId]!;
          } else {
            try {
              var cDoc = await _firestore.collection('clientes').doc(ordenModelo.clienteId).get();
              // Si falla por ID, intentamos buscar por código interno
              if (!cDoc.exists) {
                final q = await _firestore.collection('clientes').where('codigo', isEqualTo: ordenModelo.clienteId).limit(1).get();
                if(q.docs.isNotEmpty) cDoc = q.docs.first;
              }

              if (cDoc.exists) {
                final d = cDoc.data();
                clienteNombre = d?['razonSocial'] ?? d?['nombre'] ?? d?['alias'] ?? 'Cliente S/N';
                necesitaUpdate = true;
              } else {
                clienteNombre = 'Cliente (ID: ${ordenModelo.clienteId.substring(0, 4)}...)';
              }
            } catch (_) {
              clienteNombre = 'Cliente Offline';
            }
            cacheClientes[ordenModelo.clienteId] = clienteNombre;
          }
        }

        // 2. RECUPERAR OBRA (Prioridad: ALIAS -> NOMBRE -> DIRECCIÓN)
        if (obraNombre.isEmpty || obraNombre.contains('Eliminado') || obraNombre == 'Obra General' || obraNombre.contains('ID:')) {
          if (ordenModelo.obraId.isNotEmpty) {
            if (cacheObras.containsKey(ordenModelo.obraId)) {
              obraNombre = cacheObras[ordenModelo.obraId]!;
            } else {
              try {
                // Intento 1: Por ID directo
                var oDoc = await _firestore.collection('obras').doc(ordenModelo.obraId).get();

                // Intento 2: Por Código (Si el ID guardado es "O-2024..." y no el UUID)
                if (!oDoc.exists) {
                  final q = await _firestore.collection('obras').where('codigo', isEqualTo: ordenModelo.obraId).limit(1).get();
                  if(q.docs.isNotEmpty) oDoc = q.docs.first;
                }

                if (oDoc.exists) {
                  final d = oDoc.data();
                  // ✅ AQUÍ ESTÁ LA MAGIA: Busca Alias, luego Nombre, luego Dirección
                  obraNombre = d?['alias'] ?? d?['nombre'] ?? d?['direccion'] ?? 'Obra S/N';
                  necesitaUpdate = true;
                } else {
                  // Si no existe, mostramos código CORTO
                  String idCorto = ordenModelo.obraId.length > 6
                      ? ordenModelo.obraId.substring(0, 6)
                      : ordenModelo.obraId;
                  obraNombre = 'Obra ($idCorto...)';
                }
              } catch (_) {
                obraNombre = 'Obra Offline';
              }
              cacheObras[ordenModelo.obraId] = obraNombre;
            }
          } else {
            obraNombre = "Sin Obra";
          }
        }

        // 3. Persistir datos encontrados para que la próxima vez sea instantáneo
        if (necesitaUpdate) {
          doc.reference.update({
            'clienteRazonSocial': clienteNombre,
            'obraNombre': obraNombre
          });
        }

        temp.add(OrdenInternaDetalle(
            orden: ordenModelo,
            clienteRazonSocial: clienteNombre,
            obraNombre: obraNombre.isNotEmpty ? obraNombre : '---'
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

  // --- DETALLE ORDEN (Misma lógica de Alias) ---
  Future<void> cargarDetalleOrden(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _firestore.collection('ordenes_internas').doc(id).get();
      if (!doc.exists) { _ordenSeleccionada = null; return; }

      final ordenModelo = OrdenInternaModel.fromSnapshot(doc);
      final data = doc.data() as Map<String, dynamic>;

      String cName = data['clienteRazonSocial'] ?? '';
      String oName = data['obraNombre'] ?? '';

      // Recuperación al vuelo si falta el dato en el detalle
      if(cName.isEmpty || cName.contains('ID:')) {
        var cDoc = await _firestore.collection('clientes').doc(ordenModelo.clienteId).get();
        if(!cDoc.exists) {
          final q = await _firestore.collection('clientes').where('codigo', isEqualTo: ordenModelo.clienteId).limit(1).get();
          if(q.docs.isNotEmpty) cDoc = q.docs.first;
        }
        if (cDoc.exists) {
          cName = cDoc.data()?['razonSocial'] ?? cDoc.data()?['nombre'] ?? '';
        }
      }

      if((oName.isEmpty || oName.contains('ID:')) && ordenModelo.obraId.isNotEmpty) {
        var oDoc = await _firestore.collection('obras').doc(ordenModelo.obraId).get();
        if(!oDoc.exists) {
          final q = await _firestore.collection('obras').where('codigo', isEqualTo: ordenModelo.obraId).limit(1).get();
          if(q.docs.isNotEmpty) oDoc = q.docs.first;
        }

        if (oDoc.exists) {
          // ✅ Prioridad Alias -> Nombre -> Direccion
          oName = oDoc.data()?['alias'] ?? oDoc.data()?['nombre'] ?? oDoc.data()?['direccion'] ?? 'Obra';
        }
      }

      _ordenSeleccionada = OrdenInternaDetalle(
          orden: ordenModelo,
          clienteRazonSocial: cName.isNotEmpty ? cName : 'Cliente',
          obraNombre: oName.isNotEmpty ? oName : 'Obra'
      );
    } catch (e) {
      print("Error detalle: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CREAR ORDEN (Guardar Alias desde el inicio) ---
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
        var cd = await _firestore.collection('clientes').doc(clienteId).get();
        if(cd.exists) {
          clienteNombre = cd.data()?['razonSocial'] ?? cd.data()?['nombre'] ?? '';
        }

        if (obraId.isNotEmpty) {
          var od = await _firestore.collection('obras').doc(obraId).get();
          if(od.exists) {
            // ✅ Guardamos Alias si existe, sino Nombre
            obraNombre = od.data()?['alias'] ?? od.data()?['nombre'] ?? od.data()?['direccion'] ?? '';
          }
        }
      } catch(_) {}

      final ordenId = const Uuid().v4();
      final docContador = _firestore.collection('metadata').doc('contadores');
      String numeroFinal = "OI-000";

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docContador);
        int nextNumber = 1;
        if (snapshot.exists) {
          nextNumber = (snapshot.data()?['ordenes'] ?? 0) + 1;
        }
        numeroFinal = "OI-${nextNumber.toString().padLeft(3, '0')}";
        transaction.set(docContador, {'ordenes': nextNumber}, SetOptions(merge: true));
      });

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
        'numero': numeroFinal,
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
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> aprobarOrden({ required String ordenId, required String usuarioId, required List<OrdenItemDetalle> itemsModificados, String? observaciones, String? proveedorId, String? proveedorNombre, OrigenAbastecimiento? origen, }) async { try { _isLoading = true; notifyListeners(); final itemsMap = itemsModificados.map((i) => i.toMap()).toList(); final Map<String, dynamic> updateData = { 'estado': 'aprobada', 'items': itemsMap, 'aprobadoPor': usuarioId, 'fechaAprobacion': Timestamp.now(), 'observacionesAprobacion': observaciones, 'modificadoPor': usuarioId, }; if (proveedorId != null) updateData['proveedorId'] = proveedorId; if (proveedorNombre != null) updateData['proveedor'] = proveedorNombre; if (origen != null) updateData['origen'] = origen.name; await _firestore.collection('ordenes_internas').doc(ordenId).update(updateData); await cargarOrdenes(); if (_ordenSeleccionada?.orden.id == ordenId) { await cargarDetalleOrden(ordenId); } return true; } catch (e) { return false; } finally { _isLoading = false; notifyListeners(); } }
  Future<bool> actualizarLogistica({ required String ordenId, required TipoDespacho tipoDespacho, String? proveedorId, String? proveedorNombre, }) async { try { _isLoading = true; notifyListeners(); await _firestore.collection('ordenes_internas').doc(ordenId).update({ 'tipoDespacho': tipoDespacho.name, 'proveedorId': proveedorId, 'proveedor': proveedorNombre, }); await cargarOrdenes(); if (_ordenSeleccionada?.orden.id == ordenId) { await cargarDetalleOrden(ordenId); } return true; } catch (e) { return false; } finally { _isLoading = false; notifyListeners(); } }

  // --- GENERAR REMITO (Corregido 'productoId') ---
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
      String numeroOrdenLimpio = ordenDetalle.orden.numero.replaceFirst('OI-', '').replaceFirst('OI', '');
      final sufijoRemito = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
      final numeroRemito = "OI - $numeroOrdenLimpio | R - $sufijoRemito";

      List<RemitoItem> itemsRemito = [];
      for (var itemEntrega in itemsAEntregar) {
        String pId = itemEntrega['productoId'];
        double cantidadEntrega = (itemEntrega['cantidad'] as num).toDouble();

        final itemOriginal = ordenDetalle.items.firstWhere(
                (i) => i.materialId == pId || i.productoCodigo == pId,
            orElse: () => ordenDetalle.items.first
        );

        itemsRemito.add(RemitoItem(
          // ✅ CORREGIDO: ERA productId, AHORA ES productoId
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

          if (acopioData != null && acopioRef != null) {
            final idx = acopioData!.items.indexWhere((ai) => ai.productoId == itemOrig.materialId);
            if (idx != -1) {
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