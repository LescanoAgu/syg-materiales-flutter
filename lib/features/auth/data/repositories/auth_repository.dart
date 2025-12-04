import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/constants/app_roles.dart';
import '../models/usuario_model.dart';
import '../../../../core/services/notification_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> login(String email, String password) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credencial.user != null) {
        await _actualizarConfiguracionUsuario(credencial.user!.uid);
      }
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

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
        rol: AppRoles.panolero,
        estado: 'pendiente',
        permisosEspeciales: {}, // ✅ AHORA SÍ FUNCIONA ESTE PARÁMETRO
      );

      await _firestore.collection('users').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());
      await _actualizarConfiguracionUsuario(nuevoUsuario.uid);

    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  Future<void> _actualizarConfiguracionUsuario(String uid) async {
    try {
      String? token = await NotificationService().getToken();
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final rol = data['rol'] ?? 'usuario';
        final orgId = data['organizationId'] ?? 'general';

        await _messaging.subscribeToTopic('org_$orgId');
        await _messaging.subscribeToTopic('rol_$rol');

        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print("⚠️ Error config post-login: $e");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UsuarioModel?> obtenerDatosUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UsuarioModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}