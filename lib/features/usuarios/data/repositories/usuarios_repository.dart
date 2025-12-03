import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/auth/data/models/usuario_model.dart';

class UsuariosRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // Obtener usuarios de mi organización
  Future<List<UsuarioModel>> obtenerUsuarios(String organizationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('organizationId', isEqualTo: organizationId)
          .orderBy('nombre') // Requiere índice si combinas con filtro
          .get();

      return snapshot.docs.map((doc) {
        return UsuarioModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  // Actualizar rol, estado y permisos
  Future<void> actualizarUsuario(UsuarioModel usuario) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(usuario.uid)
      // ⚠️ CAMBIO: Usamos toUpdateMap() en lugar de toMap()
          .update(usuario.toUpdateMap());

      print('✅ Usuario ${usuario.uid} actualizado a rol: ${usuario.rol}, estado: ${usuario.estado}');
    } catch (e) {
      print('❌ Error repository: $e');
      throw Exception('Error actualizando usuario: $e');
    }
  }
}