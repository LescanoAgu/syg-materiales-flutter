import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'clientes';

  Future<List<ClienteModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection).orderBy('razonSocial');
      if (soloActivos) {
        query = query.where('activo', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ClienteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Error obteniendo clientes: $e");
      return [];
    }
  }

  // ✅ Método necesario para OrdenInternaRepository
  Future<ClienteModel?> obtenerPorId(String id) async {
    try {
      // Intentar por ID de documento
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ClienteModel.fromMap(doc.data()!, doc.id);
      }
      // Intentar por campo 'codigo' (Legacy support)
      final query = await _firestore.collection(_collection).where('codigo', isEqualTo: id).limit(1).get();
      if (query.docs.isNotEmpty) {
        final d = query.docs.first;
        return ClienteModel.fromMap(d.data(), d.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> guardar(ClienteModel cliente) async {
    final docRef = cliente.id.isEmpty
        ? _firestore.collection(_collection).doc() // Nuevo auto-ID
        : _firestore.collection(_collection).doc(cliente.id); // Actualizar

    // Usamos set con merge para seguridad
    await docRef.set(cliente.toMap(), SetOptions(merge: true));
  }

  Future<void> eliminar(String id) async {
    // Implementamos Soft Delete cambiando 'activo' a false
    await _firestore.collection(_collection).doc(id).update({'activo': false});
  }
}