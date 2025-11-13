// [COPIAR Y PEGAR ESTE ARCHIVO COMPLETO]
// Reemplaza tu: lib/features/obras/data/repositories/obra_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/obra_model.dart';
// Importamos el repo de clientes para desnormalizar
import '../../../clientes/data/repositories/cliente_repository.dart';

/// Repositorio de Obras (Versión Firestore)
///
/// Maneja todas las operaciones de Firestore relacionadas con obras.
class ObraRepository {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _tableName = 'obras';

  // Repositorio de clientes para obtener datos
  final ClienteRepository _clienteRepo = ClienteRepository();

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODAS las obras
  Future<List<ObraModel>> obtenerTodas({bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivas) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ObraModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener obras: $e');
      return [];
    }
  }

  /// Obtiene todas las obras con información del cliente (SIN JOIN)
  ///
  /// ¡Esto ahora es un query simple! Los datos del cliente ya están
  /// guardados (desnormalizados) en el documento de la obra.
  Future<List<ObraConCliente>> obtenerTodasConCliente({bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Asumimos que ObraConCliente.fromMap puede manejar el mapa
        // que ya contiene 'cliente_codigo' y 'cliente_razon_social'
        return ObraConCliente.fromMap(data);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener obras con cliente: $e');
      return [];
    }
  }

  /// Obtiene una obra por su ID (código)
  Future<ObraModel?> obtenerPorCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();

      if (doc.exists) {
        return ObraModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener obra por código $codigo: $e');
      return null;
    }
  }

  /// (Mantenido por compatibilidad)
  Future<ObraModel?> obtenerPorId(String id) async {
    return obtenerPorCodigo(id);
  }

  /// Obtiene todas las obras de un cliente específico
  Future<List<ObraModel>> obtenerPorCliente(String clienteCodigo, {bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      query = query.where('clienteId', isEqualTo: clienteCodigo); // Buscamos por código

      if (soloActivas) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      query = query.orderBy('nombre');
      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ObraModel.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener obras del cliente $clienteCodigo: $e');
      return [];
    }
  }

  /// Busca obras por nombre
  Future<List<ObraConCliente>> buscar(String termino, {bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (termino.isNotEmpty) {
        query = query
            .where('nombre', isGreaterThanOrEqualTo: termino)
            .where('nombre', isLessThanOrEqualTo: '$termino\uf8ff');
      }

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      query = query.orderBy('nombre');

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ObraConCliente.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      print('❌ Error al buscar obras: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea una nueva obra (con desnormalización)
  Future<void> crear(ObraModel obra) async {
    try {
      // 1. Obtenemos el cliente para desnormalizar
      final cliente = await _clienteRepo.obtenerPorCodigo(obra.clienteId); // Asumimos que clienteId es el código

      Map<String, dynamic> obraMap = obra.toMap();

      // 2. Agregamos los datos del cliente al mapa de la obra
      if (cliente != null) {
        obraMap['cliente_codigo'] = cliente.codigo;
        obraMap['cliente_razon_social'] = cliente.razonSocial;
      }

      // 3. Usamos el 'codigo' de la obra como ID del documento
      await _firestore
          .collection(_tableName)
          .doc(obra.codigo)
          .set(obraMap);

      print('✅ Obra creada con código: ${obra.codigo}');
    } catch (e) {
      print('❌ Error al crear obra: $e');
      rethrow;
    }
  }

  /// Actualiza una obra existente
  Future<void> actualizar(ObraModel obra) async {
    try {
      if (obra.id == null) {
        throw Exception("El ID (código) de la obra no puede ser nulo al actualizar");
      }

      // 1. Obtenemos el cliente para desnormalizar
      final cliente = await _clienteRepo.obtenerPorCodigo(obra.clienteId);

      Map<String, dynamic> obraMap = obra.toMap();

      // 2. Agregamos los datos del cliente al mapa de la obra
      if (cliente != null) {
        obraMap['cliente_codigo'] = cliente.codigo;
        obraMap['cliente_razon_social'] = cliente.razonSocial;
      }

      await _firestore
          .collection(_tableName)
          .doc(obra.id!)
          .update(obraMap);

      print('✅ Obra actualizada: ${obra.id}');
    } catch (e) {
      print('❌ Error al actualizar obra: $e');
      rethrow;
    }
  }

  /// Cambia el estado de una obra
  Future<void> cambiarEstado(String codigo, String nuevoEstado) async {
    try {
      await _firestore.collection(_tableName).doc(codigo).update({
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Estado de obra $codigo actualizado a $nuevoEstado');
    } catch (e) {
      print('❌ Error al cambiar estado de obra: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de obras
  Future<int> contar({bool soloActivas = true}) async {
    return contarObras(soloActivas: soloActivas);
  }

  /// Obtiene obras con paginación y cliente
  Future<List<ObraConCliente>> obtenerConPaginacion({
    required int limit,
    DocumentSnapshot? ultimoDocumento,
    bool soloActivas = true,
  }) async {
    try {
      Query query = _firestore.collection(_tableName);

      if (soloActivas) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      query = query.orderBy('nombre').limit(limit);

      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ObraConCliente.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      print('❌ Error al obtener obras con paginación: $e');
      return [];
    }
  }

  /// Cuenta el total de obras
  Future<int> contarObras({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);
      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error al contar obras: $e');
      return 0;
    }
  }

  /// Cuenta obras por cliente
  Future<int> contarPorCliente(String clienteCodigo, {bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_tableName);
      query = query.where('clienteId', isEqualTo: clienteCodigo);

      if (soloActivos) {
        query = query.where('estado', isEqualTo: 'activa');
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error al contar obras del cliente: $e');
      return 0;
    }
  }

  /// Verifica si existe una obra con un código dado
  Future<bool> existeCodigo(String codigo) async {
    try {
      final doc = await _firestore.collection(_tableName).doc(codigo).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Genera el siguiente código de obra para un cliente
  /// Formato: OB-XXX-CL-YYY
  Future<String> generarSiguienteCodigoParaCliente(String codigoCliente) async {
    try {
      // Obtener la última obra del cliente
      final snapshot = await _firestore
          .collection(_tableName)
          .where('clienteId', isEqualTo: codigoCliente)
          .orderBy('codigo', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'OB-001-$codigoCliente';
      }

      // Extraer el número del último código (OB-001-CL-001 -> 001)
      String ultimoCodigo = snapshot.docs.first.id;
      String numeroStr = ultimoCodigo.split('-')[1];
      int numero = int.parse(numeroStr);

      // Incrementar y formatear
      numero++;
      return 'OB-${numero.toString().padLeft(3, '0')}-$codigoCliente';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'OB-001-$codigoCliente';
    }
  }
}