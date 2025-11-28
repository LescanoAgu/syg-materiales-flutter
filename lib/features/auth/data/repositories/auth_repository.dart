import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';
import '../../../../core/services/notification_service.dart'; // ✅ IMPORTAR

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- REGISTRO ---
  Future<void> registrar({
    required String email,
    required String password,
    required String nombre,
    required String codigoOrganizacion,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credencial.user == null) throw Exception('Error creando usuario');

      final nuevoUsuario = UsuarioModel(
        uid: credencial.user!.uid,
        email: email,
        nombre: nombre,
        organizationId: codigoOrganizacion.toUpperCase(),
        rol: 'operario',
        estado: 'pendiente',
        permisos: {
          'ver_precios': false,
          'crear_orden': true,
          'gestionar_stock': false,
        },
      );

      await _firestore.collection('users').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());

      // ✅ Guardar Token FCM al registrarse
      await _guardarFcmToken(nuevoUsuario.uid);

    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // --- LOGIN ---
  Future<void> login(String email, String password) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // ✅ Guardar Token FCM al loguearse
      if (credencial.user != null) {
        await _guardarFcmToken(credencial.user!.uid);
      }

    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // --- HELPER PARA GUARDAR TOKEN ---
  Future<void> _guardarFcmToken(String uid) async {
    try {
      String? token = await NotificationService().getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastLogin': DateTime.now().toIso8601String(),
        });
        print("📲 Token FCM actualizado en Firestore");
      }
    } catch (e) {
      print("⚠️ No se pudo guardar el token FCM: $e");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      // Opcional: Borrar token al salir para no recibir notificaciones en cuenta cerrada
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      await _auth.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

  // --- OBTENER DATOS ---
  Future<UsuarioModel?> obtenerDatosUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UsuarioModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}