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
      // Si quieres ver todo al borrar, comenta la línea de soloActivos
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      query = query.orderBy('razonSocial');
      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ClienteModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error clientes: $e');
      return [];
    }
  }
  /// Obtiene un cliente por su ID (código o ID de documento)
  Future<ClienteModel?> obtenerPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ClienteModel.fromMap(data);
      }
      final query = await _firestore.collection(_collection).where('codigo', isEqualTo: id).limit(1).get();
      if (query.docs.isNotEmpty) {
        final d = query.docs.first;
        return ClienteModel.fromMap(d.data()..['id'] = d.id);
      }
      return null;
    } catch (e) { return null; }
  }
  // ========================================
  // ESCRITURA
  // ========================================

  Future<void> crear(ClienteModel cliente) async {
    // Usamos código como ID
    await _firestore.collection(_collection).doc(cliente.codigo).set(cliente.toMap());
  }

  Future<void> actualizar(ClienteModel cliente) async {
    String docId = cliente.id ?? cliente.codigo;
    await _firestore.collection(_collection).doc(docId).update(cliente.toMap());
  }

  // ✅ CAMBIO: Borrado REAL (Hard Delete)
  Future<void> eliminar(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      print('🗑️ Cliente eliminado: $id');
    } catch (e) {
      print('❌ Error eliminando cliente: $e');
      rethrow;
    }
  }
}