import 'package:flutter/material.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../../data/repositories/usuarios_repository.dart';

class UsuariosProvider extends ChangeNotifier {
  final UsuariosRepository _repo = UsuariosRepository();

  List<UsuarioModel> _usuarios = [];
  bool _isLoading = false;

  List<UsuarioModel> get usuarios => _usuarios;
  bool get isLoading => _isLoading;

  // Filtros rápidos
  List<UsuarioModel> get pendientes => _usuarios.where((u) => u.estado == 'pendiente').toList();
  List<UsuarioModel> get activos => _usuarios.where((u) => u.estado == 'activo').toList();

  Future<void> cargarUsuarios(String organizationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _usuarios = await _repo.obtenerUsuarios(organizationId);
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarCambiosUsuario(UsuarioModel usuario) async {
    try {
      await _repo.actualizarUsuario(usuario);
      // Actualizamos la lista localmente
      final index = _usuarios.indexWhere((u) => u.uid == usuario.uid);
      if (index != -1) {
        _usuarios[index] = usuario;
        notifyListeners();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}