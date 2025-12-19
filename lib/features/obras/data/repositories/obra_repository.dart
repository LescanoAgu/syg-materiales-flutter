import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/obra_model.dart';

class ObraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'obras';

  Future<List<ObraModel>> obtenerTodas({bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_collection).orderBy('nombre');
      if (soloActivas) {
        query = query.where('estado', isEqualTo: 'activa');
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ObraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ObraModel>> obtenerPorCliente(String clienteId) async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('clienteId', isEqualTo: clienteId)
          .orderBy('nombre')
          .get();
      return snapshot.docs
          .map((doc) => ObraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> guardar(ObraModel obra) async {
    final docRef = obra.id.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(obra.id);

    await docRef.set(obra.toMap(), SetOptions(merge: true));
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}