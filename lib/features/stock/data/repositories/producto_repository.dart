import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();

  static const String _collection = 'productos';
  static const String _stockCollection = 'stock';

  // --- LECTURA PAGINADA (LAZY LOADING + FILTROS) ---
  Future<QuerySnapshot> obtenerPaginados({
    int limite = 20,
    DocumentSnapshot? ultimoDocumento,
    String ordenarPor = 'codigo',
    String? filtroCategoriaId, // ✅ NUEVO: Filtro opcional
  }) async {
    try {
      Query query = _firestore.collection(_collection)
          .where('estado', isEqualTo: 'activo');

      // Si hay filtro de categoría, lo aplicamos
      if (filtroCategoriaId != null && filtroCategoriaId.isNotEmpty) {
        query = query.where('categoriaId', isEqualTo: filtroCategoriaId);
      }

      // Ordenamiento
      query = query.orderBy(ordenarPor);

      // Paginación
      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      return await query.limit(limite).get();
    } catch (e) {
      print('❌ Error paginación: $e');
      rethrow;
    }
  }

  // --- OBTENER TODOS (LEGACY - Opcional, para dropdowns pequeños) ---
  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true, int limite = 100}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');
      final snapshot = await query.orderBy('codigo').limit(limite).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // --- BÚSQUEDA ---
  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];
    // Nota: Firestore no soporta búsquedas parciales nativas (LIKE %...%) de forma sencilla.
    // Usamos el truco de rango Unicode para prefijos.
    final end = termino.substring(0, termino.length - 1) + String.fromCharCode(termino.codeUnitAt(termino.length - 1) + 1);

    // Buscamos por nombre (más común)
    final snapshot = await _firestore.collection(_collection)
        .where('nombre', isGreaterThanOrEqualTo: termino)
        .where('nombre', isLessThan: end)
        .limit(20)
        .get();

    return snapshot.docs.map((d) => ProductoModel.fromMap(d.data()..['id'] = d.id)).toList();
  }

  // --- BÚSQUEDA POR CÓDIGO ---
  Future<ProductoModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_collection).doc(codigo).get();
      if (doc.exists) return ProductoModel.fromMap(doc.data()!..['id'] = doc.id);
      return null;
    } catch (e) { return null; }
  }

  // --- ESCRITURA (CREAR / IMPORTAR) ---
  Future<void> crear(ProductoModel producto) async {
    String? catNombre;
    try {
      final cat = await _catRepo.obtenerPorId(producto.categoriaId);
      if (cat != null) catNombre = cat.nombre;
    } catch (_) {}

    final map = producto.toMap();
    if (catNombre != null) map['categoriaNombre'] = catNombre;

    await _firestore.collection(_collection).doc(producto.codigo).set(map);
    // Init stock espejo si no existe
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
      // Guardar producto
      final prodRef = _firestore.collection(_collection).doc(p.codigo);
      batch.set(prodRef, p.toMap());

      // Guardar stock inicial (solo si es necesario, o inicializar en 0)
      final stockRef = _firestore.collection(_stockCollection).doc(p.codigo);
      // Usamos set con merge por si ya existe el stock
      batch.set(stockRef, {
        'productoId': p.codigo,
        'cantidadDisponible': p.cantidadDisponible,
        'ultimaActualizacion': DateTime.now().toIso8601String()
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // --- ELIMINAR ---
  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    await _firestore.collection(_stockCollection).doc(id).delete();
  }

  // --- UTILIDAD CÓDIGOS ---
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