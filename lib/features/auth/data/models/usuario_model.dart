import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_roles.dart';

class UsuarioModel extends Equatable {
  final String uid;
  final String email;
  final String nombre;
  final String organizationId;
  final String rol;
  final String estado;
  final Map<String, bool> permisosEspeciales;

  const UsuarioModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.organizationId,
    this.rol = AppRoles.panolero,
    this.estado = 'pendiente',
    this.permisosEspeciales = const {},
  });

  bool tienePermiso(String permiso) {
    if (rol == AppRoles.admin) return true;
    if (estado != 'activo') return false;
    if (permisosEspeciales.containsKey(permiso)) {
      return permisosEspeciales[permiso]!;
    }
    return AppRoles.tienePermisoBase(rol, permiso);
  }

  // ✅ GETTERS NECESARIOS
  bool get esAdmin => rol == AppRoles.admin;
  bool get esJefeObra => rol == AppRoles.jefeObra;
  bool get esPanolero => rol == AppRoles.panolero;

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Usuario vacío");
    return UsuarioModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? 'Sin Nombre',
      organizationId: data['organizationId'] ?? '',
      rol: data['rol'] ?? AppRoles.panolero,
      estado: data['estado'] ?? 'pendiente',
      permisosEspeciales: Map<String, bool>.from(data['permisos'] ?? {}),
    );
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map, String uid) {
    return UsuarioModel(
      uid: uid,
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? 'Sin Nombre',
      organizationId: map['organizationId'] ?? '',
      rol: map['rol'] ?? AppRoles.panolero,
      estado: map['estado'] ?? 'pendiente',
      permisosEspeciales: Map<String, bool>.from(map['permisos'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'organizationId': organizationId,
      'rol': rol,
      'estado': estado,
      'permisos': permisosEspeciales,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'rol': rol,
      'estado': estado,
      'permisos': permisosEspeciales,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? rol,
    String? estado,
    Map<String, bool>? permisosEspeciales,
  }) {
    return UsuarioModel(
      uid: uid,
      email: email,
      organizationId: organizationId,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      permisosEspeciales: permisosEspeciales ?? this.permisosEspeciales,
    );
  }

  @override
  List<Object?> get props => [uid, organizationId, estado, rol, permisosEspeciales];
}