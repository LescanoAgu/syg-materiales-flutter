import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

/// Repositorio de Acopios
///
/// Maneja todas las operaciones relacionadas con acopios.
/// IMPORTANTE: Mantiene la integridad de saldos y movimientos.
class AcopioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'acopios';

  // ========================================
  // OPERACIONES DE LECTURA
  // ========================================

  /// Obtiene TODOS los acopios con detalle
  Future<List<AcopioDetalle>> obtenerTodosConDetalle({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        ${soloActivos ? "WHERE a.estado = 'activo' AND a.cantidad_disponible > 0" : ''}
        ORDER BY prov.nombre ASC, c.razon_social ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios con detalle: $e');
      return [];
    }
  }

  /// Obtiene acopios de un cliente específico
  Future<List<AcopioDetalle>> obtenerPorCliente(int clienteId) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE a.cliente_id = ? AND a.estado = 'activo' AND a.cantidad_disponible > 0
        ORDER BY prov.nombre ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [clienteId]);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios del cliente: $e');
      return [];
    }
  }

  /// Obtiene acopios de un proveedor específico
  Future<List<AcopioDetalle>> obtenerPorProveedor(int proveedorId) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE a.proveedor_id = ? AND a.estado = 'activo' AND a.cantidad_disponible > 0
        ORDER BY c.razon_social ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [proveedorId]);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios del proveedor: $e');
      return [];
    }
  }

  /// Obtiene un acopio específico
  Future<AcopioModel?> obtenerAcopio({
    required int productoId,
    required int clienteId,
    required int proveedorId,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, clienteId, proveedorId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return AcopioModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener acopio: $e');
      return null;
    }
  }

  /// Busca acopios por producto
  Future<List<AcopioDetalle>> buscarPorProducto(String termino) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE (p.nombre LIKE ? OR p.codigo LIKE ?)
          AND a.estado = 'activo' 
          AND a.cantidad_disponible > 0
        ORDER BY prov.nombre ASC, c.razon_social ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        query,
        ['%$termino%', '%$termino%'],
      );

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar acopios por producto: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE MOVIMIENTOS
  // ========================================

  /// Registra un movimiento de acopio
  /// IMPORTANTE: Actualiza el saldo automáticamente en una transacción
  Future<MovimientoAcopioModel> registrarMovimiento({
    required int productoId,
    required int clienteId,
    required int proveedorId,
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    double? montoValorizado,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Obtener o crear el acopio
      final acopioActual = await txn.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, clienteId, proveedorId],
      );

      double cantidadAnterior = 0;
      int? acopioId;

      if (acopioActual.isNotEmpty) {
        cantidadAnterior = acopioActual.first['cantidad_disponible'] as double;
        acopioId = acopioActual.first['id'] as int;
      }

      // 2. Calcular nueva cantidad según tipo
      double cantidadNueva;
      double cantidadMovimiento = cantidad;

      switch (tipo) {
        case TipoMovimientoAcopio.entrada:
          cantidadNueva = cantidadAnterior + cantidad;
          break;
        case TipoMovimientoAcopio.salida:
          if (cantidadAnterior < cantidad) {
            throw Exception('Acopio insuficiente. Disponible: $cantidadAnterior');
          }
          cantidadNueva = cantidadAnterior - cantidad;
          cantidadMovimiento = -cantidad;
          break;
        default:
        // Otros tipos se manejan diferente (traspasos, etc.)
          cantidadNueva = cantidadAnterior + cantidad;
      }

      // 3. Actualizar o crear acopio
      if (acopioId != null) {
        await txn.update(
          _tableName,
          {
            'cantidad_disponible': cantidadNueva,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [acopioId],
        );
      } else {
        // Crear nuevo acopio
        acopioId = await txn.insert(
          _tableName,
          {
            'producto_id': productoId,
            'cliente_id': clienteId,
            'proveedor_id': proveedorId,
            'cantidad_disponible': cantidadNueva,
            'estado': 'activo',
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }

      // 4. Insertar movimiento
      final movimiento = MovimientoAcopioModel(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad.abs(),
        origenTipo: 'acopio',
        origenId: acopioId,
        destinoTipo: null,
        destinoId: null,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        valorizado: valorizado,
        montoValorizado: montoValorizado,
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      final id = await txn.insert(
        'movimientos_acopio',
        movimiento.toMap(),
      );

      return movimiento.copyWith(id: id);
    });
  }

  /// Obtiene movimientos de un acopio
  Future<List<MovimientoAcopioModel>> obtenerMovimientos({
    int? productoId,
    int? clienteId,
    int? proveedorId,
    DateTime? desde,
    DateTime? hasta,
    int? limit,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (productoId != null) {
        where += ' AND producto_id = ?';
        whereArgs.add(productoId);
      }

      if (desde != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(desde.toIso8601String());
      }

      if (hasta != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(hasta.toIso8601String());
      }

      final maps = await db.query(
        'movimientos_acopio',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) {
        return MovimientoAcopioModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener movimientos: $e');
      return [];
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Cuenta total de acopios activos
  Future<int> contarActivos() async {
    try {
      final Database db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE estado = ? AND cantidad_disponible > 0',
          ['activo'],
        ),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar acopios: $e');
      return 0;
    }
  }
}