/// Modelo de datos para Cliente
class ClienteModel {
  final String? id;
  final String codigo;
  final String razonSocial;
  final String? cuit;
  final String? condicionIva;
  final String? condicionPago;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? localidad;
  final String? provincia;
  final String? codigoPostal;
  final String? observaciones;
  final String estado;
  final String? createdAt;
  final String? updatedAt;

  ClienteModel({
    this.id,
    required this.codigo,
    required this.razonSocial,
    this.cuit,
    this.condicionIva,
    this.condicionPago,
    this.telefono,
    this.email,
    this.direccion,
    this.localidad,
    this.provincia,
    this.codigoPostal,
    this.observaciones,
    this.estado = 'activo',
    this.createdAt,
    this.updatedAt,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      // CORRECCIÓN: Casting seguro para evitar error de Object? a String?
      id: map['id']?.toString(),
      codigo: map['codigo']?.toString() ?? '',
      razonSocial: map['razonSocial']?.toString() ?? '',
      cuit: map['cuit']?.toString(),
      condicionIva: map['condicionIva']?.toString(),
      condicionPago: map['condicionPago']?.toString(),
      telefono: map['telefono']?.toString(),
      email: map['email']?.toString(),
      direccion: map['direccion']?.toString(),
      localidad: map['localidad']?.toString(),
      provincia: map['provincia']?.toString(),
      codigoPostal: map['codigoPostal']?.toString(),
      observaciones: map['observaciones']?.toString(),
      estado: map['estado']?.toString() ?? 'activo',
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'razonSocial': razonSocial,
      'cuit': cuit,
      'condicionIva': condicionIva,
      'condicionPago': condicionPago,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'localidad': localidad,
      'provincia': provincia,
      'codigoPostal': codigoPostal,
      'observaciones': observaciones,
      'estado': estado,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isActivo => estado == 'activo';
  String get displayName => razonSocial;
  String get cuitFormateado {
    if (cuit == null || cuit!.length != 11) return cuit ?? '-';
    return '${cuit!.substring(0, 2)}-${cuit!.substring(2, 10)}-${cuit!.substring(10)}';
  }

  String get direccionCompleta {
    List<String> partes = [];
    if (direccion != null && direccion!.isNotEmpty) partes.add(direccion!);
    if (localidad != null && localidad!.isNotEmpty) partes.add(localidad!);
    return partes.isEmpty ? '-' : partes.join(', ');
  }
}