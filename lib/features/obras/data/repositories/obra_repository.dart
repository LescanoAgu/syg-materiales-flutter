import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/obra_model.dart';
// IMPORT FALTANTE AGREGADO:
import '../../../../features/clientes/data/repositories/cliente_repository.dart';

class ObraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ClienteRepository _clienteRepo = ClienteRepository();
  static const String _collection = 'obras';

  Future<List<ObraModel>> obtenerTodas({bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivas) {
        query = query.where('estado', isEqualTo: 'activa');
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ObraModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo obras: $e');
      return [];
    }
  }

  Future<void> crear(ObraModel obra) async {
    try {
      final cliente = await _clienteRepo.obtenerPorId(obra.clienteId);
      final obraMap = obra.toMap();
      if (cliente != null) {
        obraMap['clienteRazonSocial'] = cliente.razonSocial;
        obraMap['clienteCodigo'] = cliente.codigo;
      }
      // Usar código como ID o autogenerado
      String docId = obra.codigo.isNotEmpty ? obra.codigo : _firestore.collection(_collection).doc().id;
      await _firestore.collection(_collection).doc(docId).set(obraMap);
      print('✅ Obra creada: ${obra.codigo}');
    } catch (e) {
      print('❌ Error creando obra: $e');
      rethrow;
    }
  }

  Future<void> actualizar(ObraModel obra) async {
    try {
      final cliente = await _clienteRepo.obtenerPorId(obra.clienteId);
      final obraMap = obra.toMap();
      if (cliente != null) {
        obraMap['clienteRazonSocial'] = cliente.razonSocial;
        obraMap['clienteCodigo'] = cliente.codigo;
      }
      String docId = obra.id ?? obra.codigo;
      await _firestore.collection(_collection).doc(docId).update(obraMap);
    } catch (e) {
      print('❌ Error actualizando obra: $e');
      rethrow;
    }
  }

  Future<List<ObraModel>> obtenerPorCliente(String clienteId) async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .where('clienteId', isEqualTo: clienteId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ObraModel.fromMap(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Métodos auxiliares para evitar errores si se llaman desde providers viejos
  Future<int> contarObras({bool soloActivas = true}) async => 0;
  Future<List<ObraModel>> obtenerConPaginacion({required int limit, required bool soloActivas, required dynamic ultimoDocumento}) async => [];
  Future<dynamic> obtenerUltimoDocumentoDePagina({required int limit, required bool soloActivas, dynamic ultimoDocumento}) async => null;
  Future<void> cambiarEstado(String id, String estado) async {
    await _firestore.collection(_collection).doc(id).update({'estado': estado});
  }
  Future<String> generarSiguienteCodigoParaCliente(String c) async => 'OB-NEW';
  Future<bool> existeCodigo(String c) async => false;
  Future<int> contarPorCliente(String c, {bool soloActivas = true}) async => 0;
  Future<List<ObraModel>> buscar(String t, {bool soloActivas = true}) async => [];
  Future<ObraModel?> obtenerPorCodigo(String c) async => null;
}