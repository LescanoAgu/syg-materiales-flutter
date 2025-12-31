import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/producto_model.dart';
import '../models/categoria_model.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'productos';
  static const String _categoriasCollection = 'categorias';

  // --- PRODUCTOS ---

  Future<List<ProductoModel>> obtenerProductos() async {
    try {
      // ✅ CORRECCIÓN: Ordenamos por CÓDIGO, no por nombre.
      final snapshot = await _firestore.collection(_collection).orderBy('codigo').get();
      return snapshot.docs.map((doc) => ProductoModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Error repository obtenerProductos: $e");
      return [];
    }
  }

  Future<void> guardar(ProductoModel producto) async {
    final data = producto.toMap();
    // Usamos el código como ID del documento para mantener orden y unicidad
    await _firestore.collection(_collection).doc(producto.codigo).set(data);
  }

  Future<void> guardarLote(List<ProductoModel> productos) async {
    final batch = _firestore.batch();
    for (var p in productos) {
      final docRef = _firestore.collection(_collection).doc(p.codigo);
      batch.set(docRef, p.toMap());
    }
    await batch.commit();
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // --- CATEGORÍAS ---

  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final snapshot = await _firestore.collection(_categoriasCollection).orderBy('nombre').get();
      return snapshot.docs.map((doc) => CategoriaModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Error obtenerCategorias: $e");
      return [];
    }
  }

  Future<void> guardarCategoria(CategoriaModel categoria) async {
    // Usamos el código de la categoría como ID si es posible
    await _firestore.collection(_categoriasCollection).doc(categoria.codigo).set(categoria.toMap());
  }
}