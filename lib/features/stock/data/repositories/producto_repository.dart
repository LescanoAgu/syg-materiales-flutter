import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();

  static const String _collection = 'productos';
  static const String _stockCollection = 'stock';

  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true, int limite = 100}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      // IMPORTANTE: Requiere índice compuesto en Firestore
      final snapshot = await query.orderBy('nombre').limit(limite).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo productos: $e');
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
    // Desnormalizamos categoría si existe
    String? catNombre;
    try {
      final cat = await _catRepo.obtenerPorId(producto.categoriaId);
      if (cat != null) catNombre = cat.nombre;
    } catch (_) {}

    final map = producto.toMap();
    if (catNombre != null) map['categoriaNombre'] = catNombre;

    await _firestore.collection(_collection).doc(producto.codigo).set(map);
    // Init stock espejo
    await _firestore.collection(_stockCollection).doc(producto.codigo).set({
      'productoId': producto.codigo, 'cantidadDisponible': 0.0, 'ultimaActualizacion': DateTime.now().toIso8601String()
    });
  }

  // ✅ NUEVO: Eliminar
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

      String ultimo = snapshot.docs.first.id; // Ej: OG-005
      final partes = ultimo.split('-');
      if (partes.length > 1) {
        int num = int.tryParse(partes.last) ?? 0;
        return '$categoriaId-${(num + 1).toString().padLeft(3, '0')}';
      }
      return '$categoriaId-001';
    } catch (e) { return '$categoriaId-001'; }
  }

  // Método Buscar
  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];
    // Búsqueda simple por prefijo
    final end = termino.substring(0, termino.length - 1) + String.fromCharCode(termino.codeUnitAt(termino.length - 1) + 1);

    final snapshot = await _firestore.collection(_collection)
        .where('nombre', isGreaterThanOrEqualTo: termino)
        .where('nombre', isLessThan: end)
        .limit(20).get();

    return snapshot.docs.map((d) => ProductoModel.fromMap(d.data()..['id'] = d.id)).toList();
  }

  // Método Importar
  Future<void> importarMasivos(List<ProductoModel> productos) async {
    final batch = _firestore.batch();
    for (var p in productos) {
      batch.set(_firestore.collection(_collection).doc(p.codigo), p.toMap());
      batch.set(_firestore.collection(_stockCollection).doc(p.codigo), {
        'productoId': p.codigo, 'cantidadDisponible': 0.0, 'ultimaActualizacion': DateTime.now().toIso8601String()
      });
    }
    await batch.commit();
  }
}