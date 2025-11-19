import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';

/// Repositorio de Clientes (Versión Firestore)
class ClienteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'clientes';

  /// Obtiene TODOS los clientes
  Future<List<ClienteModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      // Ordenar por razón social
      query = query.orderBy('razonSocial');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Asignamos el ID del documento al modelo
        data['id'] = doc.id;
        return ClienteModel.fromMap(data);
      }).toList();

    } catch (e) {
      print('❌ Error obteniendo clientes: $e');
      return [];
    }
  }

  /// Obtiene un cliente por su ID (código o ID de documento)
  Future<ClienteModel?> obtenerPorId(String id) async {
    try {
      // Primero intentamos buscar por ID de documento
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ClienteModel.fromMap(data);
      }

      // Si no, buscamos por el campo 'codigo' (por si usas CL-001 como ID lógico)
      final query = await _firestore.collection(_collection)
          .where('codigo', isEqualTo: id)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final d = query.docs.first;
        final data = d.data();
        data['id'] = d.id;
        return ClienteModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('❌ Error buscando cliente: $e');
      return null;
    }
  }

  // ========================================
  // ESCRITURA
  // ========================================

  Future<void> crear(ClienteModel cliente) async {
    try {
      // Usamos .add() para que genere un ID automático, o .doc(codigo).set()
      // si quieres que el ID del documento sea el código (ej: CL-001).
      // Recomendación: Usar el código como ID para búsquedas rápidas.
      await _firestore.collection(_collection).doc(cliente.codigo).set(cliente.toMap());
      print('✅ Cliente creado: ${cliente.codigo}');
    } catch (e) {
      print('❌ Error creando cliente: $e');
      rethrow;
    }
  }

  Future<void> actualizar(ClienteModel cliente) async {
    try {
      // Asumimos que el ID del modelo es el ID del documento o el código
      String docId = cliente.id ?? cliente.codigo;

      await _firestore.collection(_collection).doc(docId).update(cliente.toMap());
      print('✅ Cliente actualizado');
    } catch (e) {
      print('❌ Error actualizando cliente: $e');
      rethrow;
    }
  }

  Future<void> eliminar(String id) async {
    try {
      // Soft delete (marcar como inactivo)
      await _firestore.collection(_collection).doc(id).update({
        'estado': 'inactivo',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error eliminando cliente: $e');
      rethrow;
    }
  }
}