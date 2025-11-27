import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/obra_model.dart';
import '../../../../features/clientes/data/repositories/cliente_repository.dart';

class ObraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ClienteRepository _clienteRepo = ClienteRepository();
  static const String _collection = 'obras';

  Future<List<ObraModel>> obtenerTodas({bool soloActivas = true}) async {
    try {
      Query query = _firestore.collection(_collection);
      if (soloActivas) query = query.where('estado', isEqualTo: 'activa');
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ObraModel.fromMap(data);
      }).toList();
    } catch (e) { return []; }
  }

  Future<void> crear(ObraModel obra) async {
    final cliente = await _clienteRepo.obtenerPorId(obra.clienteId);
    final map = obra.toMap();
    if (cliente != null) {
      map['clienteRazonSocial'] = cliente.razonSocial;
      map['clienteCodigo'] = cliente.codigo;
    }
    String id = obra.codigo.isNotEmpty ? obra.codigo : _firestore.collection(_collection).doc().id;
    await _firestore.collection(_collection).doc(id).set(map);
  }

  Future<void> actualizar(ObraModel obra) async {
    String id = obra.id ?? obra.codigo;
    await _firestore.collection(_collection).doc(id).update(obra.toMap());
  }

  // ✅ NUEVO: Eliminar
  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Placeholders necesarios
  Future<List<ObraModel>> obtenerPorCliente(String id) async => [];
  Future<void> cambiarEstado(String id, String est) async {}
}