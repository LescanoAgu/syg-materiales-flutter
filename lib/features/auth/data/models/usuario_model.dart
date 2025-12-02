import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UsuarioModel extends Equatable {
  final String uid;
  final String email;
  final String nombre;
  final String organizationId;
  final String rol;
  final String estado;
  final Map<String, bool> permisos;

  const UsuarioModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.organizationId,
    this.rol = 'usuario',
    this.estado = 'pendiente',
    this.permisos = const {},
  });

  bool tienePermiso(String key) {
    if (rol == 'admin') return true;
    return permisos[key] == true;
  }

  // ✅ MÉTODO QUE FALTABA: fromFirestore
  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Documento vacío para usuario ${doc.id}');
    }

    return UsuarioModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? 'Sin Nombre',
      organizationId: data['organizationId'] ?? '',
      rol: data['rol'] ?? 'usuario',
      estado: data['estado'] ?? 'pendiente',
      permisos: Map<String, bool>.from(data['permisos'] ?? {}),
    );
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
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? rol,
    String? estado,
    Map<String, bool>? permisos,
  }) {
    return UsuarioModel(
      uid: uid,
      email: email,
      organizationId: organizationId,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      estado: estado ?? this.estado,
      permisos: permisos ?? this.permisos,
    );
  }

  @override
  List<Object?> get props => [uid, organizationId, estado, permisos, rol];

  Map<String, dynamic> toUpdateMap() {
    return {
      'rol': rol,
      'estado': estado,
      'permisos': permisos,
      'updatedAt': FieldValue.serverTimestamp(),
      // Solo actualizamos la fecha de modificación

    };
  }
}