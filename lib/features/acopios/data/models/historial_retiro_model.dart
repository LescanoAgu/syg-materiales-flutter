class HistorialRetiro {
  final String id;
  final String fecha;
  final String proveedorId;
  final String proveedorNombre;
  final String clienteId;
  final String clienteNombre;
  final String obraId;
  final String obraNombre;

  // Lista simple de qué se llevó
  final List<String> descripcionItems; // ["100x Ladrillo", "20x Cemento"]
  final String remitoAsociado;

  HistorialRetiro({
    required this.id,
    required this.fecha,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.clienteId,
    required this.clienteNombre,
    required this.obraId,
    required this.obraNombre,
    required this.descripcionItems,
    required this.remitoAsociado,
  });

// Factory y toMap estándar... (los genero si me das el ok para avanzar)
}