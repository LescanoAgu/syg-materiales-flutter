import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_roles.dart';
import '../enums/app_section.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// Imports de Navegación
import '../../features/home/presentation/pages/home_hub_page.dart'; // ✅ Import verificado
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
// ✅ CORRECCIÓN: Apuntamos a DespachosListPage como indicaste
import '../../features/ordenes_internas/presentation/pages/despachos_list_page.dart';
import '../../features/acopios/presentation/pages/acopios_list_page.dart';
import '../../features/reportes/presentation/pages/reportes_menu_page.dart';
import '../../features/usuarios/presentation/pages/usuarios_list_page.dart';

class AppDrawer extends StatelessWidget {
  final AppSection? currentSection;

  const AppDrawer({super.key, this.currentSection});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.usuario;
    final rol = usuario?.rol ?? AppRoles.observador;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(usuario?.nombre ?? 'Usuario'),
            accountEmail: Text(usuario?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (usuario?.nombre ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 24, color: AppColors.primary),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, Icons.dashboard, 'Inicio', () =>
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeHubPage()))
                ),

                if (rol == AppRoles.admin || rol == AppRoles.panolero)
                  _buildItem(context, Icons.inventory, 'Stock', () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StockPage()))
                  ),

                _buildItem(context, Icons.assignment, 'Órdenes', () =>
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdenesPage()))
                ),

                if (rol == AppRoles.admin || rol == AppRoles.panolero)
                // ✅ CORRECCIÓN: Usamos DespachosListPage
                  _buildItem(context, Icons.local_shipping, 'Despachos / Entregas', () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DespachosListPage()))
                  ),

                if (rol == AppRoles.admin) ...[
                  const Divider(),
                  _buildItem(context, Icons.account_balance_wallet, 'Acopios', () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AcopiosListPage()))
                  ),
                  _buildItem(context, Icons.bar_chart, 'Reportes', () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportesMenuPage()))
                  ),
                  _buildItem(context, Icons.people, 'Usuarios', () =>
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UsuariosListPage()))
                  ),
                ]
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => authProvider.logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}