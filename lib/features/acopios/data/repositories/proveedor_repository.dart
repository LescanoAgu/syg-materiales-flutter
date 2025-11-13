// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/acopios/data/repositories/proveedor_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';

/// Repositorio de Proveedores/Ubicaciones (Versión Firestore)
///
/// Maneja todas las operaciones de BD relacionadas con proveedores.
class ProveedorRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la "colección" (tabla)
  static const String _tableName = 'proveedores';

  // ========================================
  // OPERACIONES DE LECTURA
  // ========================================

  /// Obtiene TODOS los proveedores
  Future<List<ProveedorModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProveedorModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id); // Asignamos el ID de Firestore
      }).toList();

    } catch (e) {
      print('❌ Error al obtener proveedores: $e');
      return [];
    }
  }

  /// Obtiene un proveedor por ID (código)
  Future<ProveedorModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        return ProveedorModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener proveedor por código $codigo: $e');
      return null;
    }
  }

  /// (Mantenido por compatibilidad, idealmente migrar a 'obtenerPorCodigo')
  Future<ProveedorModel?> obtenerPorId(String id) async {
    return obtenerPorCodigo(id);
  }

  /// Obtiene el depósito S&G
  Future<ProveedorModel?> obtenerDepositoSyg() async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .where('tipo', isEqualTo: 'deposito_syg')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ProveedorModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener depósito S&G: $e');
      return null;
    }
  }

  /// Busca proveedores por nombre (empieza con...)
  Future<List<ProveedorModel>> buscar(String termino, {bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (termino.isNotEmpty) {
        query = query
            .where('nombre', isGreaterThanOrEqualTo: termino)
            .where('nombre', isLessThanOrEqualTo: '$termino\uf8ff');
      }

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProveedorModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al buscar proveedores: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA
  // ========================================

  /// Crea un nuevo proveedor
  Future<void> crear(ProveedorModel proveedor) async {
    try {
      // Usamos el 'codigo' como ID del documento
      await _firestore
          .collection(_tableName)
          .doc(proveedor.codigo)
          .set(proveedor.toMap());

      print('✅ Proveedor creado con código: ${proveedor.codigo}');
    } catch (e) {
      print('❌ Error al crear proveedor: $e');
      rethrow;
    }
  }

  /// Actualiza un proveedor existente
  Future<void> actualizar(ProveedorModel proveedor) async {
    try {
      // Usamos el 'codigo' (guardado en 'id')
      if (proveedor.id == null) {
        throw Exception("El ID (código) del proveedor no puede ser nulo al actualizar");
      }

      final provConFecha = proveedor.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_tableName)
          .doc(proveedor.id!)
          .update(provConFecha.toMap());

      print('✅ Proveedor actualizado');
    } catch (e) {
      print('❌ Error al actualizar proveedor: $e');
      rethrow;
    }
  }

  /// Cambia el estado de un proveedor
  Future<void> cambiarEstado(String codigo, String nuevoEstado) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Estado de proveedor actualizado a: $nuevoEstado');
    } catch (e) {
      print('❌ Error al cambiar estado: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Verifica si existe un código
  Future<bool> existeCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Genera el siguiente código disponible
  Future<String> generarSiguienteCodigo() async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .where('codigo', isGreaterThanOrEqualTo: 'PROV-')
          .where('codigo', isLessThan: 'PROV-Z')
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'PROV-001';
      }

      String ultimoCodigo = snapshot.docs.first.id;
      String numeroStr = ultimoCodigo.split('-').last;
      int numero = int.parse(numeroStr);

      numero++;
      return 'PROV-${numero.toString().padLeft(3, '0')}';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'PROV-001';
    }
  }
}