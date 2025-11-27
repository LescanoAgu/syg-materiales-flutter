import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

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

      // 2. Crear ficha en Firestore (PENDIENTE)
      final nuevoUsuario = UsuarioModel(
        uid: credencial.user!.uid,
        email: email,
        nombre: nombre,
        organizationId: codigoOrganizacion.toUpperCase(),
        rol: 'operario', // ✅ FIX: Cambiado de rolBase a rol
        estado: 'pendiente', // 🔒 Importante
        permisos: {
          'ver_precios': false,
          'crear_orden': true,
          'gestionar_stock': false,
        },
      );

      await _firestore.collection('users').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // --- LOGIN ---
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
  }

  // --- OBTENER DATOS COMPLETOS (Perfil) ---
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