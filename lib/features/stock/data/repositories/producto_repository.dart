import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();

  static const String _collection = 'productos';
  static const String _stockCollection = 'stock';

  // --- GENERACIÓN INTELIGENTE DE CÓDIGOS ---
  Future<String> generarSiguienteCodigo(String categoriaId, String prefijo) async {
    try {
      // 1. Buscamos todos los productos de esta categoría para encontrar el último número
      final snapshot = await _firestore.collection(_collection)
          .where('categoriaId', isEqualTo: categoriaId)
          .get();

      int maxNum = 0;

      for (var doc in snapshot.docs) {
        final codigo = doc.id; // El ID del doc es el código (ej: A-001 o A001)

        // Limpiamos el código para dejar solo los números
        // Esto permite leer "A001" del CSV y "A-001" manuales y entender ambos
        final soloNumeros = codigo.replaceAll(RegExp(r'[^0-9]'), '');

        if (soloNumeros.isNotEmpty) {
          final num = int.tryParse(soloNumeros) ?? 0;
          if (num > maxNum) maxNum = num;
        }
      }

      // 2. Generamos el siguiente: PREFIJO + GUION + NUMERO (Padding 3)
      // Ejemplo: Si max es 1 -> A-002
      return '$prefijo-${(maxNum + 1).toString().padLeft(3, '0')}';

    } catch (e) {
      // Fallback de seguridad
      return '$prefijo-001';
    }
  }

  // ... (RESTO DE MÉTODOS DE LECTURA/ESCRITURA IGUALES AL ANTERIOR) ...
  // Copio los esenciales para que el archivo esté completo y no rompa nada

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
      rethrow;
    }
  }

  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('estado', isEqualTo: 'activo')
          .limit(100)
          .get();
      final term = termino.toLowerCase().trim();
      final resultados = snapshot.docs.map((d) {
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
}