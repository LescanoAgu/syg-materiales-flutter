import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';

class ProveedorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'proveedores';

  Future<List<ProveedorModel>> obtenerProveedores() async {
    try {
      final snapshot = await _firestore.collection(_collection).orderBy('nombre').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Pasamos el ID explícitamente en el segundo argumento opcional que agregamos al factory
        return ProveedorModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Error cargando proveedores: $e");
    }
  }

  Future<void> crearProveedor(ProveedorModel proveedor) async {
    await _firestore.collection(_collection).add(proveedor.toMap());
  }

  Future<void> actualizarProveedor(ProveedorModel proveedor) async {
    if (proveedor.id == null) return;
    await _firestore.collection(_collection).doc(proveedor.id).update(proveedor.toMap());
  }

  Future<void> eliminarProveedor(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}