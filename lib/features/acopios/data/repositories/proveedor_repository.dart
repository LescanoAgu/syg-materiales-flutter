import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';

class ProveedorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'proveedores';

  Future<List<ProveedorModel>> obtenerTodos() async {
    try {
      final snapshot = await _firestore.collection(_collection).orderBy('nombre').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProveedorModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error proveedores: $e');
      return [];
    }
  }

  Future<void> crear(ProveedorModel proveedor) async {
    await _firestore.collection(_collection).doc(proveedor.codigo).set(proveedor.toMap());
  }
}