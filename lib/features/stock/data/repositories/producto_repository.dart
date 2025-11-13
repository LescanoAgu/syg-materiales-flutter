// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/stock/data/repositories/producto_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto_model.dart';
// Importamos el repo de categorías para poder obtener sus datos
import 'categoria_repository.dart';

/// Repositorio de Productos (Versión Firestore)
///
/// Maneja todas las operaciones de base de datos (Firestore) relacionadas con productos.
/// Ahora incluye datos de categoría "desnormalizados" para evitar JOINs.
class ProductoRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la "colección" (equivalente a la "tabla")
  static const String _tableName = 'productos';

  // Repositorio de categorías para obtener datos al crear/actualizar
  final CategoriaRepository _categoriaRepo = CategoriaRepository();

  // ========================================
  // LECTURA (READ) - Operaciones básicas
  // ========================================

  /// Obtiene TODOS los productos activos ordenados por código
  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      // 1. Apuntar a la colección
      Query query = _firestore.collection(_tableName);

      // 2. Aplicar filtros (si es necesario)
      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      // 3. Ordenar
      query = query.orderBy('codigo');

      // 4. Obtener los datos
      final snapshot = await query.get();

      // 5. Convertir cada "documento" a nuestro modelo
      return snapshot.docs.map((doc) {
        // Pasamos el ID del documento al modelo
        return ProductoModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id); // Asignamos el ID de Firestore
      }).toList();

    } catch (e) {
      print('❌ Error al obtener productos desde Firestore: $e');
      return [];
    }
  }

  /// Obtiene un producto por su ID (código)
  /// OJO: En Firestore, el ID es el 'codigo' (ej: "OG-001")
  Future<ProductoModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        return ProductoModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id); // Asignamos el ID de Firestore
      }

      return null;

    } catch (e) {
      print('❌ Error al obtener producto por código $codigo: $e');
      return null;
    }
  }

  // ========================================
  // LECTURA "CON CATEGORÍA" (Datos desnormalizados)
  // ========================================

  /// Obtiene todos los productos CON información de su categoría
  ///
  /// NOTA: Esto ahora es más rápido. Asumimos que al guardar el producto,
  /// también guardamos 'categoriaNombre' y 'categoriaCodigo'.
  Future<List<ProductoConCategoria>> obtenerTodosConCategoria({
    bool soloActivos = true,
  }) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('codigo');

      final snapshot = await query.get();

      // Mapeamos directamente a ProductoConCategoria
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Agregamos el ID del documento
        data['id'] = doc.id;
        return ProductoConCategoria.fromMap(data);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener productos con categoría: $e');
      return [];
    }
  }

  /// Obtiene un producto por ID con su categoría
  Future<ProductoConCategoria?> obtenerPorIdConCategoria(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoConCategoria.fromMap(data);
      }

      return null;

    } catch (e) {
      print('❌ Error al obtener producto por id con categoría: $e');
      return null;
    }
  }

  // ========================================
  // FILTROS Y BÚSQUEDAS
  // ========================================

  /// Obtiene productos de una categoría específica
  Future<List<ProductoModel>> obtenerPorCategoria(
      int categoriaId, { // Mantenemos el "int" por ahora
        bool soloActivos = true,
      }) async {
    try {
      Query query = _firestore.collection(_tableName);

      query = query.where('categoriaId', isEqualTo: categoriaId);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProductoModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener productos por categoría: $e');
      return [];
    }
  }

  /// Busca productos por nombre (búsqueda "empieza con")
  /// OJO: Firestore no soporta 'LIKE %termino%'.
  Future<List<ProductoModel>> buscar(
      String termino, {
        bool soloActivos = true,
      }) async {
    try {
      Query query = _firestore.collection(_tableName);

      // Firestore no permite 'OR' en campos diferentes.
      // La mejor forma es buscar por un solo campo o usar Algolia/Typesense.
      // Por ahora, buscaremos por nombre.
      if (termino.isNotEmpty) {
        query = query
            .where('nombre', isGreaterThanOrEqualTo: termino)
            .where('nombre', isLessThanOrEqualTo: '$termino\uf8ff');
      }

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProductoModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al buscar productos: $e');
      return [];
    }
  }

  /// Busca productos CON categoría
  Future<List<ProductoConCategoria>> buscarConCategoria(
      String termino, {
        bool soloActivos = true,
      }) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (termino.isNotEmpty) {
        query = query
            .where('nombre', isGreaterThanOrEqualTo: termino)
            .where('nombre', isLessThanOrEqualTo: '$termino\uf8ff');
      }

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ProductoConCategoria.fromMap(data);
      }).toList();

    } catch (e) {
      print('❌ Error al buscar productos con categoría: $e');
      return [];
    }
  }

  /// Filtra productos por rango de precios
  Future<List<ProductoModel>> filtrarPorPrecio(
      double precioMin,
      double precioMax, {
        bool soloActivos = true,
      }) async {
    try {
      Query query = _firestore.collection(_tableName);

      query = query
          .where('precioSinIva', isGreaterThanOrEqualTo: precioMin)
          .where('precioSinIva', isLessThanOrEqualTo: precioMax);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      query = query.orderBy('precioSinIva');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ProductoModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al filtrar por precio: $e');
      return [];
    }
  }

  // ========================================
  // ESCRITURA (CREATE / UPDATE / DELETE)
  // ========================================

  /// Crea un nuevo producto
  /// Usamos el 'codigo' como ID del documento
  Future<void> crear(ProductoModel producto) async {
    try {
      // 1. Buscamos la categoría para "desnormalizar" los datos
      // ¡Asegúrate que tu CategoriaRepository también esté migrado!
      final categoria = await _categoriaRepo.obtenerPorId(producto.categoriaId);

      // 2. Convertimos el modelo a Map
      Map<String, dynamic> productoMap = producto.toMap();

      // 3. Agregamos los datos de la categoría
      if (categoria != null) {
        productoMap['categoriaNombre'] = categoria.nombre;
        productoMap['categoriaCodigo'] = categoria.codigo;
      }

      // 4. Quitamos el 'id' (int) que venía de SQLite
      productoMap.remove('id');

      // 5. Guardamos en Firestore usando el 'codigo' como ID
      await _firestore
          .collection(_tableName)
          .doc(producto.codigo) // Usamos el código como ID
          .set(productoMap); // .set() crea o sobrescribe

      print('✅ Producto creado con código: ${producto.codigo}');

    } catch (e) {
      print('❌ Error al crear producto: $e');
      rethrow;
    }
  }

  /// Actualiza un producto existente
  Future<void> actualizar(ProductoModel producto) async {
    try {
      // 1. Buscamos la categoría por si cambió
      final categoria = await _categoriaRepo.obtenerPorId(producto.categoriaId);

      // 2. Convertimos a Map
      final productoConFecha = producto.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );
      Map<String, dynamic> productoMap = productoConFecha.toMap();

      // 3. Agregamos datos de categoría
      if (categoria != null) {
        productoMap['categoriaNombre'] = categoria.nombre;
        productoMap['categoriaCodigo'] = categoria.codigo;
      }

      // 4. Quitamos el 'id' (int)
      productoMap.remove('id');

      // 5. Actualizamos en Firestore usando el 'codigo'
      await _firestore
          .collection(_tableName)
          .doc(producto.codigo)
          .update(productoMap); // .update() actualiza campos

      print('✅ Producto actualizado: ${producto.codigo}');

    } catch (e) {
      print('❌ Error al actualizar producto: $e');
      rethrow;
    }
  }

  /// Marca un producto como inactivo (soft delete)
  /// CAMBIO: Ahora recibe 'codigo' (String) en lugar de 'id' (int)
  Future<void> desactivar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': 'inactivo',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Producto desactivado: $codigo');

    } catch (e) {
      print('❌ Error al desactivar producto: $e');
      rethrow;
    }
  }

  /// Reactiva un producto
  /// CAMBIO: Ahora recibe 'codigo' (String) en lugar de 'id' (int)
  Future<void> activar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': 'activo',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Producto activado: $codigo');

    } catch (e) {
      print('❌ Error al activar producto: $e');
      rethrow;
    }
  }

  /// Elimina un producto permanentemente (hard delete)
  /// CAMBIO: Ahora recibe 'codigo' (String) en lugar de 'id' (int)
  Future<void> eliminar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).delete();
      print('✅ Producto eliminado: $codigo');
    } catch (e) {
      print('❌ Error al eliminar producto: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILIDADES Y ESTADÍSTICAS
  // ========================================

  /// Cuenta el total de productos (activos o todos)
  Future<int> contar({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activo');
      }

      // Usamos .count() para obtener solo el número
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;

    } catch (e) {
      print('❌ Error al contar productos: $e');
      return 0;
    }
  }

  /// Cuenta productos por categoría
  /// OJO: Firestore NO soporta 'GROUP BY'.
  /// Esta lógica debe hacerse en el CLIENTE (en el Provider).
  Future<Map<int, int>> contarPorCategoria() async {
    print('⚠️ ADVERTENCIA: contarPorCategoria() no es eficiente en Firestore.');
    print('   -> Esta lógica debería moverse al ProductoProvider.');
    try {
      // Obtenemos TODOS los productos activos
      final productos = await obtenerTodos(soloActivos: true);

      Map<int, int> conteo = {};
      for (var producto in productos) {
        conteo.update(producto.categoriaId, (value) => value + 1, ifAbsent: () => 1);
      }
      return conteo;

    } catch (e) {
      print('❌ Error al contar por categoría: $e');
      return {};
    }
  }

  /// Verifica si existe un código
  Future<bool> existeCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Genera el siguiente código disponible para una categoría
  Future<String> generarSiguienteCodigo(String codigoCategoria) async {
    try {
      // Buscar el último código de esa categoría
      final snapshot = await _firestore
          .collection(_tableName)
          .where('codigo', isGreaterThanOrEqualTo: '$codigoCategoria-')
          .where('codigo', isLessThan: '$codigoCategoria-Z')
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Primera vez: OG-001
        return '$codigoCategoria-001';
      }

      // Extraer el número del último código
      String ultimoCodigo = snapshot.docs.first.id; // doc.id es el código
      String numeroStr = ultimoCodigo.split('-').last;
      int numero = int.parse(numeroStr);

      // Incrementar y formatear con 3 dígitos
      String nuevoCodigo = '$codigoCategoria-${(numero + 1).toString().padLeft(3, '0')}';

      return nuevoCodigo;

    } catch (e) {
      print('❌ Error al generar código: $e');
      return '$codigoCategoria-001'; // Fallback
    }
  }
}