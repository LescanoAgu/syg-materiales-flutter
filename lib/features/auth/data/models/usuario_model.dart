import 'package:equatable/equatable.dart';

class UsuarioModel extends Equatable {
  final String uid;
  final String email;
  final String nombre;
  final String organizationId; // 🏢 Clave para separar empresas
  final String rol;            // 'admin', 'usuario', 'pañolero', etc.
  final String estado;         // 'pendiente', 'activo', 'bloqueado'
  final Map<String, bool> permisos; // 🎛️ Permisos granulares

  const UsuarioModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.organizationId,
    this.rol = 'usuario',
    this.estado = 'pendiente',
    this.permisos = const {},
  });

  // Helper para verificar permisos rápido
  bool tienePermiso(String key) {
    if (rol == 'admin') return true; // Admin todo poderoso
    return permisos[key] == true;
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map, String uid) {
    return UsuarioModel(
      uid: uid,
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? 'Sin Nombre',
      organizationId: map['organizationId'] ?? '',
      rol: map['rol'] ?? 'usuario',
      estado: map['estado'] ?? 'pendiente',
      permisos: Map<String, bool>.from(map['permisos'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'organizationId': organizationId,
      'rol': rol,
      'estado': estado,
      'permisos': permisos,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // ✅ MÉTODO QUE FALTABA: copyWith
  UsuarioModel copyWith({
    String? nombre,
    String? rol,
    String? estado,
    Map<String, bool>? permisos,
  }) {
    return UsuarioModel(
      uid: uid,
      email: email,
      organizationId: organizationId, // Estos no suelen cambiar
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      permisos: permisos ?? this.permisos,
    );
  }

  @override
  List<Object?> get props => [uid, organizationId, estado, permisos, rol];
}