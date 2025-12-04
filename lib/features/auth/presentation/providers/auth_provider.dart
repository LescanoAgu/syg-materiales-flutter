import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { checking, authenticated, unauthenticated, pending }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UsuarioModel? _usuarioDb;
  AuthStatus _status = AuthStatus.checking;
  String? _errorMessage;

  AuthStatus get status => _status;
  UsuarioModel? get usuario => _usuarioDb;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Escuchar cambios de sesión
    _repo.authStateChanges.listen((User? user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _usuarioDb = null;
        notifyListeners();
      } else {
        _cargarDatosDeUsuario(user.uid);
      }
    });
  }

  Future<void> _cargarDatosDeUsuario(String uid) async {
    try {
      _usuarioDb = await _repo.obtenerDatosUsuario(uid);

      if (_usuarioDb == null) {
        _status = AuthStatus.unauthenticated;
      } else if (_usuarioDb!.estado == 'pendiente' ||
          _usuarioDb!.estado == 'bloqueado') {
        _status = AuthStatus.pending;
      } else {
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      print("========================================");
      print("🚨 ERROR LEYENDO FIRESTORE: $e");
      print("========================================");
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      await _repo.login(email, password);
      return true;
    } catch (e) {
      print("========================================");
      print("🚨 ERROR REAL DE LOGIN: $e");
      print("========================================");
      _errorMessage = "Error técnico: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrar(
    String email,
    String pass,
    String nombre,
    String orgId,
  ) async {
    _errorMessage = null;
    try {
      await _repo.registrar(
        email: email,
        password: pass,
        nombre: nombre,
        codigoOrganizacion: orgId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
  }
}
