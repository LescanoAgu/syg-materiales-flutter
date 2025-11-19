class ObraModel {
  final String? id;
  final String codigo;
  final String clienteId;
  final String nombre;
  final String direccion;
  final String? horariosDescarga;
  final String? contactoObra;
  final String? telefonoObra;
  final String? maestroObraNombre;
  final String? maestroObraTelefono;
  final String estado;
  final String? createdAt;

  // Campos desnormalizados
  final String? clienteRazonSocial;
  final String? clienteCodigo;

  ObraModel({
    this.id,
    required this.codigo,
    required this.clienteId,
    required this.nombre,
    required this.direccion,
    this.horariosDescarga,
    this.contactoObra,
    this.telefonoObra,
    this.maestroObraNombre,
    this.maestroObraTelefono,
    this.estado = 'activa',
    this.createdAt,
    this.clienteRazonSocial, // Inicializado aquí
    this.clienteCodigo,      // Inicializado aquí
  });

  factory ObraModel.fromMap(Map<String, dynamic> map) {
    return ObraModel(
      id: map['id']?.toString(),
      codigo: map['codigo']?.toString() ?? '',
      clienteId: map['clienteId']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      direccion: map['direccion']?.toString() ?? '',
      horariosDescarga: map['horariosDescarga']?.toString(),
      contactoObra: map['contactoObra']?.toString(),
      telefonoObra: map['telefonoObra']?.toString(),
      maestroObraNombre: map['maestroObraNombre']?.toString(),
      maestroObraTelefono: map['maestroObraTelefono']?.toString(),
      estado: map['estado']?.toString() ?? 'activa',
      createdAt: map['createdAt']?.toString(),
      clienteRazonSocial: map['clienteRazonSocial']?.toString(),
      clienteCodigo: map['clienteCodigo']?.toString(),
    );
  }

  // Método necesario para evitar el error 'argument_type_not_assignable' en ObraConCliente
  // Básicamente, si usas ObraModel como ObraConCliente en la UI
  String get nombreCompleto => '$nombre - ${clienteRazonSocial ?? "Sin cliente"}';

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'clienteId': clienteId,
      'nombre': nombre,
      'direccion': direccion,
      'horariosDescarga': horariosDescarga,
      'contactoObra': contactoObra,
      'telefonoObra': telefonoObra,
      'maestroObraNombre': maestroObraNombre,
      'maestroObraTelefono': maestroObraTelefono,
      'estado': estado,
      'createdAt': createdAt,
      'clienteRazonSocial': clienteRazonSocial,
      'clienteCodigo': clienteCodigo,
    };
  }
}

// Alias para compatibilidad con código viejo que espera esta clase
typedef ObraConCliente = ObraModel;