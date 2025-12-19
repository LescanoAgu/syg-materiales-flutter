import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'clientes';

  Future<List<ClienteModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      Query query = _firestore.collection(_collection).orderBy('razonSocial');
      if (soloActivos) {
        query = query.where('activo', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ClienteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ClienteModel?> obtenerPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ClienteModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ GUARDAR UN SOLO CLIENTE (Auto-incremental)
  Future<void> guardar(ClienteModel cliente) async {
    if (cliente.id.isNotEmpty) {
      // Si tiene ID, es actualización
      await _firestore.collection(_collection).doc(cliente.id).update(cliente.toMap());
    } else {
      // Si es nuevo, usamos transacción para el ID correlativo
      await _firestore.runTransaction((transaction) async {
        // 1. Referencia al contador
        final contadorRef = _firestore.collection('sistema').doc('contadores');
        final contadorDoc = await transaction.get(contadorRef);

        // 2. Calcular siguiente número
        int nuevoNum = 1;
        if (contadorDoc.exists) {
          nuevoNum = (contadorDoc.data()?['clientes_count'] as int? ?? 0) + 1;
        }

        // 3. Formato CL-001
        String codigoCorrelativo = 'CL-${nuevoNum.toString().padLeft(3, '0')}';

        final nuevoCliente = ClienteModel(
          id: '',
          codigo: codigoCorrelativo, // ✅ Código asignado aquí
          razonSocial: cliente.razonSocial,
          cuit: cliente.cuit,
          email: cliente.email,
          telefono: cliente.telefono,
          direccion: cliente.direccion,
          localidad: cliente.localidad,
          condicionIva: cliente.condicionIva,
          activo: true,
          createdAt: DateTime.now(),
        );

        // 4. Guardar
        final docRef = _firestore.collection(_collection).doc();
        transaction.set(docRef, nuevoCliente.toMap());
        transaction.set(contadorRef, {'clientes_count': nuevoNum}, SetOptions(merge: true));
      });
    }
  }

  // ✅ IMPORTACIÓN MASIVA (Optimizado)
  Future<void> importarMasivos(List<ClienteModel> clientes) async {
    final batch = _firestore.batch();

    // Leemos el contador actual UNA VEZ (operación de lectura simple)
    // Nota: Si hay alta concurrencia esto podría colisionar, pero para importación administrativa está bien.
    final contadorDoc = await _firestore.collection('sistema').doc('contadores').get();
    int contadorBase = contadorDoc.data()?['clientes_count'] ?? 0;

    for (var c in clientes) {
      contadorBase++; // Incrementamos localmente
      String codigo = 'CL-${contadorBase.toString().padLeft(3, '0')}'; // CL-001

      final docRef = _firestore.collection(_collection).doc();

      // Ajustamos el modelo con el código generado
      final map = c.toMap();
      map['codigo'] = codigo;
      map['createdAt'] = Timestamp.now();

      batch.set(docRef, map);
    }

    // Actualizamos el contador global al final
    batch.set(_firestore.collection('sistema').doc('contadores'), {'clientes_count': contadorBase}, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> eliminar(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}