import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../../data/repositories/usuarios_repository.dart';

class UsuariosProvider extends ChangeNotifier {
  final UsuariosRepository _repo = UsuariosRepository();

  List<UsuarioModel> _usuarios = [];
  bool _isLoading = false;
  String? _error;

  List<UsuarioModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtros rápidos
  List<UsuarioModel> get pendientes => _usuarios.where((u) => u.estado == 'pendiente').toList();
  List<UsuarioModel> get activos => _usuarios.where((u) => u.estado == 'activo').toList();

  Future<void> cargarUsuarios(String organizationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _usuarios = await _repo.obtenerUsuarios(organizationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarCambiosUsuario(UsuarioModel usuario) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.actualizarUsuario(usuario);
      // Actualizamos la lista localmente para reflejar cambios inmediatos
      final index = _usuarios.indexWhere((u) => u.uid == usuario.uid);
      if (index != -1) {
        _usuarios[index] = usuario;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}