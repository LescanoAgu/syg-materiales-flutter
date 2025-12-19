import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
// Imports
import '../../../../clientes/presentation/pages/clientes_list_page.dart';
import '../../../../clientes/presentation/pages/clientes_import_page.dart';
import '../../../../obras/presentation/pages/obras_list_page.dart';
import '../../../../usuarios/presentation/pages/usuarios_list_page.dart';
import '../../../../reportes/presentation/pages/reportes_menu_page.dart';
import '../../../../acopios/presentation/pages/proveedores_list_page.dart';
import '../../../../stock/presentation/pages/catalogo_page.dart'; // Importación
import '../../../../stock/presentation/pages/gestion_catalogo_page.dart'; // ✅ GESTIÓN MANUAL

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administración"), backgroundColor: Colors.purple),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, "Reportes", "Excel y Métricas", Icons.bar_chart, const ReportesMenuPage()),
          const Divider(),

          const Padding(padding: EdgeInsets.all(8), child: Text("STOCK & PRODUCTOS", style: TextStyle(color: Colors.grey, fontSize: 12))),
          // ✅ GESTIÓN DEL CATÁLOGO
          _tile(context, "ABM Productos", "Crear, Editar y Eliminar", Icons.edit_note, const GestionCatalogoPage()),
          _tile(context, "Importar Masivo", "Cargar CSV", Icons.upload_file, const CatalogoPage()),
          const Divider(),

          const Padding(padding: EdgeInsets.all(8), child: Text("NEGOCIO", style: TextStyle(color: Colors.grey, fontSize: 12))),
          _tile(context, "Directorio Clientes", "Gestionar empresas", Icons.business, const ClientesListPage()),
          _tile(context, "Importar Clientes", "Carga masiva CSV", Icons.group_add, const ClientesImportPage()),
          _tile(context, "Proveedores", "Gestión de compras", Icons.store, const ProveedoresListPage()),
          const Divider(),

          const Padding(padding: EdgeInsets.all(8), child: Text("SISTEMA", style: TextStyle(color: Colors.grey, fontSize: 12))),
          _tile(context, "Obras", "Proyectos en curso", Icons.location_city, const ObrasListPage()),
          _tile(context, "Equipo", "Usuarios y Permisos", Icons.people, const UsuariosListPage()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String sub, IconData icon, Widget page) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.1), child: Icon(icon, color: Colors.purple)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}