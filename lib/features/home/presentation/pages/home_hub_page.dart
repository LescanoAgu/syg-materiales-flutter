import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/home_menu_card.dart';

// ✅ CORRECCIÓN IMPORTS: Si no usaste carpeta 'modules', quita 'modules/'
// Si sí la usaste, asegúrate de que exista.
// Aquí asumo que están en la misma carpeta 'pages' para simplificar o ajusta según tu estructura real.
import 'modules/admin_menu_page.dart';
import 'modules/stock_menu_page.dart';
import 'modules/pedidos_menu_page.dart';
import 'modules/acopios_menu_page.dart';

class HomeHubPage extends StatelessWidget {
  const HomeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final rol = usuario?.rol ?? AppRoles.observador;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text("S&G Materiales"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Hola, ${usuario?.nombre.split(' ')[0]}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  HomeMenuCard(
                    title: "Stock",
                    subtitle: "Catálogo e Inventario",
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                    onTap: () => _nav(context, const StockMenuPage()),
                  ),
                  HomeMenuCard(
                    title: "Pedidos",
                    subtitle: "Órdenes y Despachos",
                    icon: Icons.assignment,
                    color: Colors.orange,
                    onTap: () => _nav(context, const PedidosMenuPage()),
                  ),
                  if (rol == AppRoles.admin || rol == AppRoles.panolero || rol == AppRoles.jefeObra)
                    HomeMenuCard(
                      title: "Acopios",
                      subtitle: "Billeteras de Clientes",
                      icon: Icons.savings,
                      color: Colors.green,
                      onTap: () => _nav(context, const AcopiosMenuPage()),
                    ),
                  if (rol == AppRoles.admin)
                    HomeMenuCard(
                      title: "Admin",
                      subtitle: "Configuración Global",
                      icon: Icons.admin_panel_settings,
                      color: Colors.purple,
                      onTap: () => _nav(context, const AdminMenuPage()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}