class AppRoles {
  AppRoles._();

  static const String admin = 'admin';
  static const String jefeObra = 'jefe_obra';
  static const String panolero = 'panolero';
  static const String observador = 'observador';

  static const Map<String, String> labels = {
    admin: '🛡️ Administrador',
    jefeObra: '👷 Jefe de Obra',
    panolero: '📦 Pañolero',
    observador: '👀 Observador',
  };

  // Permisos
  static const String verPrecios = 'ver_precios';
  static const String crearOrden = 'crear_orden';
  static const String aprobarOrden = 'aprobar_orden';
  static const String gestionarStock = 'gestionar_stock';
  static const String gestionarUsuarios = 'gestionar_usuarios';
  static const String verReportes = 'ver_reportes';

  static bool tienePermisoBase(String rol, String permiso) {
    switch (rol) {
      case admin:
        return true;
      case jefeObra:
        return [verPrecios, crearOrden, verReportes].contains(permiso);
      case panolero:
        return [crearOrden, gestionarStock].contains(permiso);
      case observador:
        return [verReportes].contains(permiso);
      default:
        return false;
    }
  }
}