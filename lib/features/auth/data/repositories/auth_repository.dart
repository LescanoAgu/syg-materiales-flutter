import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ Importar Messaging
import '../models/usuario_model.dart';
import '../../../../core/services/notification_service.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance; // ✅ Instancia

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- LOGIN ---
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
        rol: 'operario', // Por defecto entra como operario
        estado: 'pendiente',
        permisos: {
          'ver_precios': false,
          'crear_orden': true,
          'gestionar_stock': false,
        },
      );

      await _firestore.collection('users').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());
      await _actualizarConfiguracionUsuario(nuevoUsuario.uid);

    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // --- CONFIGURACIÓN POST-LOGIN (Token y Tópicos) ---
  Future<void> _actualizarConfiguracionUsuario(String uid) async {
    try {
      // 1. Guardar Token FCM
      String? token = await NotificationService().getToken();

      // 2. Obtener datos del usuario para saber su rol
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final rol = data['rol'] ?? 'usuario';
        final orgId = data['organizationId'] ?? 'general';

        // 3. Suscribir a Tópicos de Firebase Messaging
        // Esto permite enviar notificaciones masivas a "todos los admins" o "toda la empresa X"
        await _messaging.subscribeToTopic('org_$orgId'); // Mensajes para toda la empresa
        await _messaging.subscribeToTopic('rol_$rol');   // Mensajes para el rol (ej: rol_admin)

        // Actualizar BD
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print("⚠️ Error configurando usuario post-login: $e");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      // Desuscribir (Opcional, pero buena práctica si cambia de usuario en el mismo cel)
      // Nota: Se requiere conocer los tópicos anteriores, por simplicidad solo borramos token
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _messaging.deleteToken(); // Invalida el token actual
      }
      await _auth.signOut();
    } catch (_) {
      await _auth.signOut();
    }
  }

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