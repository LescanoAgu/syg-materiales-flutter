import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();

  static const String _collection = 'productos';
  static const String _stockCollection = 'stock';

  Future<QuerySnapshot> obtenerPaginados({
    int limite = 20,
    DocumentSnapshot? ultimoDocumento,
    String ordenarPor = 'codigo',
    String? filtroCategoriaId,
  }) async {
    try {
      Query query = _firestore.collection(_collection).where('estado', isEqualTo: 'activo');
      if (filtroCategoriaId != null && filtroCategoriaId.isNotEmpty) {
        query = query.where('categoriaId', isEqualTo: filtroCategoriaId);
      }
      query = query.orderBy(ordenarPor);
      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }
      return await query.limit(limite).get();
    } catch (e) {
      print('❌ Error paginación: $e');
      rethrow;
    }
  }

  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('estado', isEqualTo: 'activo')
          .limit(1000)
          .get();
      final term = termino.toLowerCase().trim();
      final resultados = snapshot.docs.map((d) {
        // ✅ CORRECCIÓN: Eliminado cast innecesario y limpiado el código
        final data = d.data();
        data['id'] = d.id;
        return ProductoModel.fromMap(data);
      }).where((p) {
        final nombre = p.nombre.toLowerCase();
        final codigo = p.codigo.toLowerCase();
        final cat = (p.categoriaNombre ?? '').toLowerCase();
        return nombre.contains(term) || codigo.contains(term) || cat.contains(term);
      }).take(50).toList();
      return resultados;
    } catch (e) {
      return [];
    }
  }

  Future<ProductoModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_collection).doc(codigo).get();
      if (doc.exists) return ProductoModel.fromMap(doc.data()!..['id'] = doc.id);
      return null;
    } catch (e) { return null; }
  }

  Future<void> crear(ProductoModel producto) async {
    String? catNombre;
    try {
      final cat = await _catRepo.obtenerPorId(producto.categoriaId);
      if (cat != null) catNombre = cat.nombre;
    } catch (_) {}
    final map = producto.toMap();
    if (catNombre != null) map['categoriaNombre'] = catNombre;
    await _firestore.collection(_collection).doc(producto.codigo).set(map);

    final stockDoc = await _firestore.collection(_stockCollection).doc(producto.codigo).get();
    if (!stockDoc.exists) {
      await _firestore.collection(_stockCollection).doc(producto.codigo).set({
        'productoId': producto.codigo,
        'cantidadDisponible': 0.0,
        'ultimaActualizacion': DateTime.now().toIso8601String()
      });
    }
  }

  Future<void> importarMasivos(List<ProductoModel> productos) async {
    final batch = _firestore.batch();
    for (var p in productos) {
      final prodRef = _firestore.collection(_collection).doc(p.codigo);
      batch.set(prodRef, p.toMap());
      final stockRef = _firestore.collection(_stockCollection).doc(p.codigo);
      batch.set(stockRef, {
        'productoId': p.codigo,
        'cantidadDisponible': p.cantidadDisponible,
        'ultimaActualizacion': DateTime.now().toIso8601String()
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    await _firestore.collection(_stockCollection).doc(id).delete();
  }

  Future<String> generarSiguienteCodigo(String categoriaId) async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('categoriaId', isEqualTo: categoriaId)
          .orderBy('codigo', descending: true).limit(1).get();
      if (snapshot.docs.isEmpty) return '$categoriaId-001';
      String ultimo = snapshot.docs.first.id;
      final partes = ultimo.split('-');
      if (partes.length > 1) {
        int num = int.tryParse(partes.last) ?? 0;
        return '$categoriaId-${(num + 1).toString().padLeft(3, '0')}';
      }
      return '$categoriaId-001';
    } catch (e) { return '$categoriaId-001'; }
  }
}