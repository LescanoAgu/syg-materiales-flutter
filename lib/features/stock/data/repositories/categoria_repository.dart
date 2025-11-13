// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/stock/data/repositories/categoria_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

/// Repositorio de Categorías (Versión Firestore)
///
/// Maneja TODAS las operaciones de base de datos (Firestore)
/// relacionadas con categorías.
class CategoriaRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la "colección" (tabla)
  static const String _tableName = 'categorias';

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODAS las categorías ordenadas por 'orden'
  Future<List<CategoriaModel>> obtenerTodas() async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .orderBy('orden')
          .get();

      // Convertir cada "documento" a un CategoriaModel
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Asignamos el ID de Firestore (que es el 'codigo')
        return CategoriaModel.fromMap(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error al obtener categorías desde Firestore: $e');
      return []; // Devolver lista vacía en caso de error
    }
  }

  /// Obtiene una categoría por su ID (que ahora es el CÓDIGO)
  Future<CategoriaModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        return CategoriaModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener categoría por código $codigo: $e');
      return null;
    }
  }

  /// (Este método es por compatibilidad, ya que 'producto' usa categoriaId (int))
  /// (Lo ideal a futuro es que ProductoModel use 'categoriaCodigo' (String))
  Future<CategoriaModel?> obtenerPorId(int id) async {
    try {
      print("⚠️ ADVERTENCIA: Se está buscando categoría por 'id' numérico (int). Lo ideal es buscar por 'codigo' (String).");
      // Esta query es menos eficiente, pero mantiene compatibilidad
      final snapshot = await _firestore
          .collection(_tableName)
          .where('id_sqlite', isEqualTo: id) // Asumimos un campo 'id_sqlite' si lo necesitaras
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return CategoriaModel.fromMap(doc.data()).copyWith(id: doc.id);
      }

      // Fallback por si 'id' se guardó como int (mala práctica en Firestore)
      // Esto fallará si el id es un string.
      try {
        final doc = await _firestore.collection(_tableName).doc(id.toString()).get();
        if (doc.exists) {
          return CategoriaModel.fromMap(doc.data() as Map<String, dynamic>).copyWith(id: doc.id);
        }
      } catch (e) {
        // Ignorar error, probablemente era un String
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener categoría por id $id: $e');
      return null;
    }
  }


  /// Busca categorías por nombre (búsqueda "empieza con")
  Future<List<CategoriaModel>> buscarPorNombre(String termino) async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .where('nombre', isGreaterThanOrEqualTo: termino)
          .where('nombre', isLessThanOrEqualTo: '$termino\uf8ff')
          .orderBy('nombre')
          .get();

      return snapshot.docs.map((doc) {
        return CategoriaModel.fromMap(doc.data()).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error al buscar categorías por nombre "$termino": $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea una nueva categoría
  Future<void> crear(CategoriaModel categoria) async {
    try {
      // Usamos el 'codigo' como ID del documento
      await _firestore
          .collection(_tableName)
          .doc(categoria.codigo)
          .set(categoria.toMap());

      print('✅ Categoría creada con código: ${categoria.codigo}');
    } catch (e) {
      print('❌ Error al crear categoría: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría existente
  Future<void> actualizar(CategoriaModel categoria) async {
    try {
      // Usamos el 'codigo' (que está en el 'id' del modelo) para actualizar
      if (categoria.id == null) {
        throw Exception("El ID (código) de la categoría no puede ser nulo al actualizar");
      }
      await _firestore
          .collection(_tableName)
          .doc(categoria.id!)
          .update(categoria.toMap());

      print('✅ Categoría actualizada: ${categoria.id}');
    } catch (e) {
      print('❌ Error al actualizar categoría: $e');
      rethrow;
    }
  }

  /// Elimina una categoría permanentemente
  Future<void> eliminar(String codigo) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).delete();
      print('✅ Categoría eliminada: $codigo');
    } catch (e) {
      print('❌ Error al eliminar categoría: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de categorías
  Future<int> contarTodas() async {
    try {
      final snapshot = await _firestore.collection(_tableName).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error al contar categorías: $e');
      return 0;
    }
  }

  /// Verifica si existe una categoría con un código dado
  Future<bool> existeCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Obtiene la categoría con el orden más alto (último)
  Future<CategoriaModel?> obtenerUltima() async {
    try {
      final snapshot = await _firestore
          .collection(_tableName)
          .orderBy('orden', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return CategoriaModel.fromMap(doc.data()).copyWith(id: doc.id);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener última categoría: $e');
      return null;
    }
  }
}