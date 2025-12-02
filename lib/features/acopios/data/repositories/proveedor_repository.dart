import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';

class ProveedorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'proveedores';

  Future<List<ProveedorModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection).orderBy('nombre');
      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProveedorModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error proveedores: $e');
      return [];
    }
  }

  Future<void> crear(ProveedorModel proveedor) async {
    final id = proveedor.codigo.isNotEmpty ? proveedor.codigo : _firestore.collection(_collection).doc().id;
    await _firestore.collection(_collection).doc(id).set(proveedor.toMap());
  }

  Future<void> actualizar(ProveedorModel proveedor) async {
    if (proveedor.id == null) return;
    await _firestore.collection(_collection).doc(proveedor.id).update(proveedor.toMap());
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}