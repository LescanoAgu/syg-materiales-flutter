import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    try {
      print("🔐 Intentando login con email: $email");

      // Verifica que Firebase esté inicializado
      if (_auth.app.name.isEmpty) {
        throw Exception("Firebase no está inicializado correctamente");
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("✅ Login exitoso para: ${credential.user?.email}");
      return credential;

    } on FirebaseAuthException catch (e) {
      print("🚨 FirebaseAuthException Code: ${e.code}");
      print("🚨 FirebaseAuthException Message: ${e.message}");

      // Mensajes más específicos según el error
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No existe una cuenta con este email');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        case 'too-many-requests':
          throw Exception('Demasiados intentos. Intenta más tarde');
        case 'network-request-failed':
          throw Exception('Error de conexión. Verifica tu internet');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      print("🚨 Error general: $e");
      rethrow;
    }
  }

  Future<UsuarioModel?> obtenerDatosUsuario(String uid) async {
    try {
      print("📝 Obteniendo datos de usuario: $uid");

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print("⚠️ Usuario no existe en Firestore");
        return null;
      }

      print("✅ Datos de usuario obtenidos");
      return UsuarioModel.fromFirestore(doc);

    } catch (e) {
      print("🚨 Error obteniendo datos: $e");
      rethrow;
    }
  }

  Future<UserCredential> registrar({
    required String email,
    required String password,
    required String nombre,
    required String codigoOrganizacion,
  }) async {
    try {
      print("📝 Registrando usuario: $email");

      // 1. Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      print("✅ Usuario creado en Auth: $uid");

      // 2. Crear documento en Firestore
      await _firestore.collection('users').doc(uid).set({
        'nombre': nombre,
        'email': email,
        'organizationId': codigoOrganizacion,
        'estado': 'pendiente',
        'rol': 'usuario',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      print("✅ Documento creado en Firestore");
      return credential;

    } on FirebaseAuthException catch (e) {
      print("🚨 Error en registro - Code: ${e.code}");

      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Este email ya está registrado');
        case 'invalid-email':
          throw Exception('Email inválido');
        case 'weak-password':
          throw Exception('La contraseña es muy débil');
        default:
          throw Exception('Error al registrar: ${e.message}');
      }
    } catch (e) {
      print("🚨 Error general en registro: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print("👋 Cerrando sesión");
      await _auth.signOut();
      print("✅ Sesión cerrada");
    } catch (e) {
      print("🚨 Error al cerrar sesión: $e");
      rethrow;
    }
  }
}