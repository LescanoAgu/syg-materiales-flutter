import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();
  static const String _collection = 'productos';

  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error productos: $e');
      return [];
    }
  }

  // Alias para compatibilidad
  Future<ProductoModel?> obtenerPorId(String id) async => obtenerPorCodigo(id);

  Future<ProductoModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_collection).doc(codigo).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> crear(ProductoModel producto) async {
    try {
      final cat = await _catRepo.obtenerPorId(producto.categoriaId);
      final map = producto.toMap();
      if (cat != null) {
        map['categoriaNombre'] = cat.nombre;
        map['categoriaCodigo'] = cat.codigo;
      }
      await _firestore.collection(_collection).doc(producto.codigo).set(map);
    } catch (e) {
      print('❌ Error creando producto: $e');
      rethrow;
    }
  }

  Future<void> actualizar(ProductoModel producto) async {
    try {
      String id = producto.id ?? producto.codigo;
      await _firestore.collection(_collection).doc(id).update(producto.toMap());
    } catch (e) {
      print('❌ Error actualizando: $e');
      rethrow;
    }
  }

  Future<int> contar({bool soloActivos = true}) async {
    final snapshot = await _firestore.collection(_collection).count().get();
    return snapshot.count ?? 0;
  }

  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];
    final endTerm = termino.substring(0, termino.length - 1) +
        String.fromCharCode(termino.codeUnitAt(termino.length - 1) + 1);
    final snapshot = await _firestore.collection(_collection)
        .where('nombre', isGreaterThanOrEqualTo: termino)
        .where('nombre', isLessThan: endTerm)
        .get();
    return snapshot.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return ProductoModel.fromMap(data);
    }).toList();
  }

  /// Genera el siguiente código (Ej: OG-005)
  Future<String> generarSiguienteCodigo(String codigoCategoria) async {
    try {
      // Buscamos el último producto de esa categoría
      final snapshot = await _firestore.collection(_collection)
          .where('categoriaId', isEqualTo: codigoCategoria) // O 'categoriaCodigo'
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return '$codigoCategoria-001';

      String ultimoCodigo = snapshot.docs.first.id; // Ej: OG-004
      // Extraer número
      final partes = ultimoCodigo.split('-');
      if (partes.length > 1) {
        int num = int.tryParse(partes.last) ?? 0;
        return '$codigoCategoria-${(num + 1).toString().padLeft(3, '0')}';
      }
      return '$codigoCategoria-001';
    } catch (e) {
      return '$codigoCategoria-001';
    }
  }
}