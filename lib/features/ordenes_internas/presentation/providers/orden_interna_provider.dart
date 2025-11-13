// lib/features/ordenes_internas/presentation/providers/orden_interna_provider.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

/// Provider de Órdenes Internas
/// VERSIÓN CORREGIDA - Acceso directo a BD
class OrdenInternaProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Estado
  List<Map<String, dynamic>> _ordenes = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get ordenes => _ordenes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _ordenes.isNotEmpty;
  bool get hasError => _errorMessage != null;

  // ========================================
  // CARGAR ÓRDENES
  // ========================================

  Future<void> cargarOrdenes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      _ordenes = await db.rawQuery('''
        SELECT 
          oi.*,
          c.razon_social as cliente_nombre,
          o.nombre as obra_nombre
        FROM ordenes_internas oi
        LEFT JOIN clientes c ON oi.cliente_id = c.id
        LEFT JOIN obras o ON oi.obra_id = o.id
        ORDER BY oi.created_at DESC
      ''');

      print('✅ ${_ordenes.length} órdenes cargadas');
    } catch (e) {
      _errorMessage = 'Error: $e';
      print('❌ $_errorMessage');
      _ordenes = [];
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
    required int clienteId,
    required int obraId,
    required String solicitanteNombre,
    List<Map<String, dynamic>>? items,
    DateTime? fechaSolicitud,
    String? prioridad,
    String? observaciones,
    int usuarioId = 1,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final db = await _dbHelper.database;

      // Generar código
      final maxNum = Sqflite.firstIntValue(
        await db.rawQuery('SELECT MAX(CAST(SUBSTR(codigo, 4) AS INTEGER)) FROM ordenes_internas WHERE codigo LIKE "OI-%"'),
      ) ?? 0;
      final codigo = 'OI-${(maxNum + 1).toString().padLeft(4, '0')}';

      // Insertar orden
      final ordenId = await db.insert('ordenes_internas', {
        'numero': codigo,  // ← Cambio: "codigo" → "numero"
        'cliente_id': clienteId,
        'obra_id': obraId,
        'solicitante_nombre': solicitanteNombre,
        'fecha_pedido': (fechaSolicitud ?? DateTime.now()).toIso8601String(),  // ← Cambio: "fecha_solicitud" → "fecha_pedido"
        'estado': 'solicitado',
        'observaciones_cliente': observaciones,  // ← Cambio: "observaciones" → "observaciones_cliente"
        'usuario_creador_id': usuarioId,  // ← Cambio: "usuario_id" → "usuario_creador_id"
        'total': 0,  // ← AGREGAR este campo
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Orden creada con ID: $ordenId');

      // Insertar items
      if (items != null && items.isNotEmpty) {
        for (var item in items) {
          final cantidad = item['cantidad'] as double;
          final precio = item['precioUnitario'] as double;

          await db.insert('orden_items', {
            'orden_id': ordenId,
            'producto_id': item['productoId'],
            'cantidad_solicitada': cantidad,  // ← Cambio
            'precio_unitario': precio,
            'subtotal': cantidad * precio,  // ← AGREGAR
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        print('✅ ${items.length} items agregados');
      }

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
  // CAMBIAR ESTADO (método público que falta)
  // ========================================

  Future<bool> cambiarEstado({
    required int ordenId,
    required String nuevoEstado,
    String? observaciones,
  }) async {
    return await _actualizarEstado(
      ordenId: ordenId,
      nuevoEstado: nuevoEstado,
      observaciones: observaciones,
    );
  }

  // ========================================
  // APROBAR/RECHAZAR/CANCELAR
  // ========================================

  Future<bool> aprobarOrden(
      int ordenId, {
        int? aprobadoPorUsuarioId,
        String? observacionesInternas,
      }) async {
    return await _actualizarEstado(
      ordenId: ordenId,
      nuevoEstado: 'aprobado',
      observaciones: observacionesInternas,
      usuarioId: aprobadoPorUsuarioId,
    );
  }

  Future<bool> rechazarOrden(
      int ordenId, {
        int? rechazadoPorUsuarioId,
        String? motivoRechazo,
      }) async {
    return await _actualizarEstado(
      ordenId: ordenId,
      nuevoEstado: 'rechazado',
      observaciones: motivoRechazo,
      usuarioId: rechazadoPorUsuarioId,
    );
  }

  Future<bool> cancelarOrden(int ordenId, {String? motivo}) async {
    return await _actualizarEstado(
      ordenId: ordenId,
      nuevoEstado: 'cancelado',
      observaciones: motivo,
    );
  }

  // ========================================
  // ACTUALIZAR ESTADO (método privado)
  // ========================================

  Future<bool> _actualizarEstado({
    required int ordenId,
    required String nuevoEstado,
    String? observaciones,
    int? usuarioId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final db = await _dbHelper.database;

      final updateData = {
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (observaciones != null) {
        updateData['observaciones_internas'] = observaciones;
      }

      if (nuevoEstado == 'aprobado' && usuarioId != null) {
        updateData['aprobado_por'] = usuarioId.toString(); // ← Convertir a String
        updateData['aprobado_fecha'] = DateTime.now().toIso8601String();
      }

      if (nuevoEstado == 'rechazado') {
        updateData['motivo_rechazo'] = observaciones ?? ''; // ← Manejar null
        if (usuarioId != null) {
          updateData['rechazado_por'] = usuarioId.toString(); // ← Convertir a String
        }
      }

      await db.update(
        'ordenes_internas',
        updateData,
        where: 'id = ?',
        whereArgs: [ordenId],
      );

      await cargarOrdenes();
      _isLoading = false;
      notifyListeners();

      print('✅ Orden $ordenId -> $nuevoEstado');
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
  // FILTROS
  // ========================================

  Future<void> filtrarPorEstado(String? estado) async {
    await cargarOrdenes();
    if (estado != null) {
      _ordenes = _ordenes.where((o) => o['estado'] == estado).toList();
      notifyListeners();
    }
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================

  int contarPorEstado(String estado) {
    return _ordenes.where((o) => o['estado'] == estado).length;
  }

  int get totalOrdenes => _ordenes.length;
  int get ordenesPendientes =>
      contarPorEstado('solicitado') +
          contarPorEstado('aprobado') +
          contarPorEstado('en_preparacion');
  int get ordenesCompletadas => contarPorEstado('despachado');
  int get ordenesSolicitadas => contarPorEstado('solicitado');
  int get ordenesEnPreparacion => contarPorEstado('en_preparacion');
  int get ordenesDespachadas => contarPorEstado('despachado');
}