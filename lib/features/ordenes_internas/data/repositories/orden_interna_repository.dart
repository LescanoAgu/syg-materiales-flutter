import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orden_interna_model.dart';

class OrdenInternaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'ordenes_internas';

  Future<String> crearOrden({
    required String clienteId,
    required String obraId,
    required String solicitanteNombre,
    String? titulo,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items,
    String? usuarioCreadorId,
    String prioridad = 'media',
    bool esRetiroAcopio = false,
    String? acopioId,
  }) async {
    return _firestore.runTransaction((transaction) async {
      final contadorRef = _firestore.collection('sistema').doc('contadores');
      final contadorDoc = await transaction.get(contadorRef);

      int nuevoNum = 1000;
      if (contadorDoc.exists) {
        nuevoNum = (contadorDoc.data()?['ordenes_count'] as int? ?? 1000) + 1;
      }

      String nuevoNumString = nuevoNum.toString().padLeft(4, '0');
      final nuevaOrdenRef = _firestore.collection(_collection).doc();

      final ordenData = {
        'numero': nuevoNumString,
        'titulo': titulo,
        'clienteId': clienteId,
        'obraId': obraId,
        'solicitanteNombre': solicitanteNombre,
        'fechaPedido': Timestamp.now(),
        'estado': 'pendiente',
        'prioridad': prioridad,
        'observacionesCliente': observacionesCliente,
        'creadorId': usuarioCreadorId,
        'items': items,
        'createdAt': Timestamp.now(),
        'usuariosEtiquetados': [],
        'esRetiroAcopio': esRetiroAcopio,
        'acopioId': acopioId,
      };

      transaction.set(nuevaOrdenRef, ordenData);
      transaction.set(contadorRef, {'ordenes_count': nuevoNum}, SetOptions(merge: true));

      return nuevaOrdenRef.id;
    });
  }

  Future<List<OrdenInternaDetalle>> getOrdenes() async {
    try {
      final snapshot = await _firestore.collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // ✅ CORREGIDO: Usamos el modelo para parsear
        final orden = OrdenInternaModel.fromMap(data, doc.id);

        return OrdenInternaDetalle(
          orden: orden,
          clienteRazonSocial: data['clienteRazonSocial'] ?? '?',
          obraNombre: data['obraNombre'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}