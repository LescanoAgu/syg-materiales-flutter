import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual de Firebase Auth
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios de estado (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- REGISTRO (Sign Up) ---
  // Crea el usuario en Auth Y ADEMÁS crea el documento en Firestore
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String codigoOrganizacion, // El usuario debe saber esto para unirse
  }) async {
    try {
      // 1. Crear en Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) throw Exception("Error creando usuario");

      // 2. Definir permisos iniciales por defecto (según lógica de negocio)
      // Por defecto un operario nuevo no ve precios ni aprueba gente
      Map<String, bool> permisosIniciales = {
        'ver_precios': false,
        'crear_orden': true,
        'gestionar_stock': false,
      };

      // 3. Crear documento en Firestore (Base de datos)
      final nuevoUsuario = UsuarioModel(
        uid: userCredential.user!.uid,
        email: email,
        nombre: nombre,
        organizationId: codigoOrganizacion.toUpperCase(), // Normalizamos a mayúsculas
        rol: 'operario',
        estado: 'pendiente', // <--- IMPORTANTE: Entra como pendiente
        permisos: permisosIniciales,
      );

      await _firestore
          .collection('users')
          .doc(nuevoUsuario.uid)
          .set(nuevoUsuario.toMap());

    } on FirebaseAuthException catch (e) {
      throw _manejarErrorFirebase(e);
    } catch (e) {
      throw Exception('Error desconocido en registro: $e');
    }
  }

  // --- LOGIN (Sign In) ---
  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Nota: Aquí no verificamos si está activo/pendiente.
      // Eso se hace en la UI o en un Provider intermedio para redirigirlo a la pantalla de "Espera".
    } on FirebaseAuthException catch (e) {
      throw _manejarErrorFirebase(e);
    }
  }

  // --- LOGOUT ---
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // --- LEER DATOS DEL USUARIO (Perfil) ---
  Future<UsuarioModel?> obtenerDatosUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UsuarioModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error obteniendo datos de usuario: $e');
      return null;
    }
  }

  // Helper de errores
  String _manejarErrorFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'Usuario no encontrado';
      case 'wrong-password': return 'Contraseña incorrecta';
      case 'email-already-in-use': return 'El email ya está registrado';
      case 'invalid-email': return 'Email inválido';
      case 'weak-password': return 'La contraseña es muy débil';
      default: return 'Error de autenticación: ${e.message}';
    }
  }
}