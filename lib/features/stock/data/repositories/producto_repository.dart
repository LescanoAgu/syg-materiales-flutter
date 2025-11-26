import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
import 'categoria_repository.dart';

class ProductoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoriaRepository _catRepo = CategoriaRepository();

  static const String _collection = 'productos';
  static const String _stockCollection = 'stock';

  // 1. OBTENER TODOS (Optimizado con límite)
  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true, int limite = 50}) async {
    try {
      print('🔍 [DEBUG] Intentando leer colección: $_collection'); // <--- NUEVO

      Query query = _firestore.collection(_collection);
      if (soloActivos) query = query.where('estado', isEqualTo: 'activo');

      final snapshot = await query
          .orderBy('nombre')
          .limit(limite)
          .get();

      print('✅ [DEBUG] Documentos encontrados: ${snapshot.docs.length}'); // <--- NUEVO

      if (snapshot.docs.isNotEmpty) {
        print('📄 [DEBUG] Primer documento: ${snapshot.docs.first.data()}'); // <--- NUEVO
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ [DEBUG] Error CRÍTICO leyendo productos: $e'); // <--- NUEVO
      return [];
    }
  }

  // 2. OBTENER POR CÓDIGO / ID
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

  // 3. CREAR (Recuperado y mejorado)
  Future<void> crear(ProductoModel producto) async {
    try {
      // Intentamos desnormalizar la categoría
      String? catNombre;
      String? catCodigo;
      try {
        final cat = await _catRepo.obtenerPorId(producto.categoriaId);
        if (cat != null) {
          catNombre = cat.nombre;
          catCodigo = cat.codigo;
        }
      } catch (_) {}

      final map = producto.toMap();
      if (catNombre != null) {
        map['categoriaNombre'] = catNombre;
        map['categoriaCodigo'] = catCodigo;
      }

      // Guardamos el producto
      await _firestore.collection(_collection).doc(producto.codigo).set(map);

      // Inicializamos el stock en 0 para que exista en la otra colección
      await _firestore.collection(_stockCollection).doc(producto.codigo).set({
        'productoId': producto.codigo,
        'cantidadDisponible': 0.0,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      print('❌ Error creando producto: $e');
      rethrow;
    }
  }

  // 4. ACTUALIZAR (Recuperado)
  Future<void> actualizar(ProductoModel producto) async {
    try {
      String id = producto.id ?? producto.codigo;
      await _firestore.collection(_collection).doc(id).update(producto.toMap());
    } catch (e) {
      print('❌ Error actualizando: $e');
      rethrow;
    }
  }

  // 5. CONTAR (Recuperado)
  Future<int> contar({bool soloActivos = true}) async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // 6. BUSCAR (Optimizado con límite)
  Future<List<ProductoModel>> buscar(String termino) async {
    if (termino.isEmpty) return [];

    // Truco para búsqueda por prefijo en Firestore
    final endTerm = termino.substring(0, termino.length - 1) +
        String.fromCharCode(termino.codeUnitAt(termino.length - 1) + 1);

    final snapshot = await _firestore.collection(_collection)
        .where('nombre', isGreaterThanOrEqualTo: termino)
        .where('nombre', isLessThan: endTerm)
        .limit(20) // Limitamos resultados para no saturar
        .get();

    return snapshot.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return ProductoModel.fromMap(data);
    }).toList();
  }

  // 7. GENERAR CÓDIGO (Recuperado)
  Future<String> generarSiguienteCodigo(String codigoCategoria) async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('categoriaId', isEqualTo: codigoCategoria)
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return '$codigoCategoria-001';

      String ultimoCodigo = snapshot.docs.first.id;
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

  // 8. IMPORTACIÓN MASIVA (Nuevo)
  Future<void> importarMasivos(List<ProductoModel> productos) async {
    final batch = _firestore.batch();

    for (var prod in productos) {
      final prodRef = _firestore.collection(_collection).doc(prod.codigo);
      batch.set(prodRef, prod.toMap());

      final stockRef = _firestore.collection(_stockCollection).doc(prod.codigo);
      batch.set(stockRef, {
        'productoId': prod.codigo,
        'cantidadDisponible': 0.0,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }
}