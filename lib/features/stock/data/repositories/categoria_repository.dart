import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'categorias';

  Future<List<CategoriaModel>> obtenerTodas() async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .orderBy('orden') // Asegúrate de crear este índice en Firebase si falla
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CategoriaModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo categorías: $e');
      return [];
    }
  }

  Future<CategoriaModel?> obtenerPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return CategoriaModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> crear(CategoriaModel categoria) async {
    // Usamos el código (ej: "OG", "H") como ID del documento
    await _firestore.collection(_collection).doc(categoria.codigo).set(categoria.toMap());
  }
}