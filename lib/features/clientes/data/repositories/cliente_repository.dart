// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/clientes/data/repositories/cliente_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';

/// Repositorio de Clientes (Versión Firestore)
///
/// Maneja todas las operaciones de Firestore relacionadas con clientes.
class ClienteRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la "colección" (tabla)
  static const String _tableName = 'clientes';

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODOS los clientes
  Future<List<ClienteModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('razon_social');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ClienteModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id); // Asignamos el ID de Firestore
      }).toList();

    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      return [];
    }
  }

  /// Obtiene clientes con paginación
  Future<List<ClienteModel>> obtenerConPaginacion({
    required int limit,
    required int offset, // Firestore usa 'startAfter' no 'offset'
    DocumentSnapshot? ultimoDocumento, // Necesitamos el último doc para paginar
    bool soloActivos = true,
  }) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('razon_social').limit(limit);

      // Si nos pasan el último documento, paginamos desde ahí
      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ClienteModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener clientes con paginación: $e');
      return [];
    }
  }

  /// Cuenta el total de clientes
  Future<int> contarClientes({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);
      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;

    } catch (e) {
      print('❌ Error al contar clientes: $e');
      return 0;
    }
  }

  /// Obtiene un cliente por su ID (código)
  Future<ClienteModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        return ClienteModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener cliente por código $codigo: $e');
      return null;
    }
  }

  /// (Mantenido por compatibilidad, idealmente migrar a 'obtenerPorCodigo')
  Future<ClienteModel?> obtenerPorId(String id) async {
    return obtenerPorCodigo(id);
  }


  /// Busca clientes por razón social (empieza con...)
  Future<List<ClienteModel>> buscar(String termino, {bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (termino.isNotEmpty) {
        query = query
            .where('razon_social', isGreaterThanOrEqualTo: termino)
            .where('razon_social', isLessThanOrEqualTo: '$termino\uf8ff');
      }

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('razon_social');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ClienteModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al buscar clientes: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea un nuevo cliente
  Future<void> crear(ClienteModel cliente) async {
    try {
      // Usamos el 'codigo' como ID del documento
      await _firestore
          .collection(_tableName)
          .doc(cliente.codigo)
          .set(cliente.toMap());

      print('✅ Cliente creado con código: ${cliente.codigo}');
    } catch (e) {
      print('❌ Error al crear cliente: $e');
      rethrow;
    }
  }

  /// Actualiza un cliente existente
  Future<void> actualizar(ClienteModel cliente) async {
    try {
      // Usamos el 'codigo' (guardado en 'id')
      if (cliente.id == null) {
        throw Exception("El ID (código) del cliente no puede ser nulo al actualizar");
      }
      await _firestore
          .collection(_tableName)
          .doc(cliente.id!)
          .update(cliente.toMap());

      print('✅ Cliente actualizado: ${cliente.id}');
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      rethrow;
    }
  }

  /// Elimina un cliente (soft delete - marca como inactivo)
  Future<void> eliminar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': 'inactivo',
        'updated_at': DateTime.now().toIso8601String()
      });

      print('✅ Cliente marcado como inactivo: $codigo');
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      rethrow;
    }
  }

  /// Restaura un cliente inactivo
  Future<void> restaurar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': 'activo',
        'updated_at': DateTime.now().toIso8601String()
      });

      print('✅ Cliente restaurado: $codigo');
    } catch (e) {
      print('❌ Error al restaurar cliente: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de clientes
  Future<int> contar({bool soloActivos = true}) async {
    return contarClientes(soloActivos: soloActivos);
  }

  /// Verifica si existe un cliente con un código dado
  Future<bool> existeCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Verifica si existe un cliente con un CUIT dado
  Future<bool> existeCuit(String cuit) async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .where('cuit', isEqualTo: cuit)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar CUIT: $e');
      return false;
    }
  }

  /// Genera el siguiente código de cliente (CL-XXX)
  Future<String> generarSiguienteCodigo() async {
    try {
      // Obtener el último código
      final snapshot = await _firestore
          .collection(_tableName)
          .where('codigo', isGreaterThanOrEqualTo: 'CL-')
          .where('codigo', isLessThan: 'CL-Z')
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();


      if (snapshot.docs.isEmpty) {
        return 'CL-001';
      }

      // Extraer el número del último código (CL-001 -> 001)
      String ultimoCodigo = snapshot.docs.first.id;
      String numeroStr = ultimoCodigo.split('-').last;
      int numero = int.parse(numeroStr);

      // Incrementar y formatear
      numero++;
      return 'CL-${numero.toString().padLeft(3, '0')}';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'CL-001';
    }
  }
}