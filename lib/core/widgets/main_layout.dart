import 'package:flutter/material.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../features/clientes/presentation/pages/clientes_list_page.dart';
import '../constants/app_colors.dart';
import 'app_drawer.dart';

// Definimos las secciones para saber qué menú mostrar en el Drawer
enum AppSection { stock, ordenes, admin }

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Lista de secciones
  final List<AppSection> _sections = [
    AppSection.stock,
    AppSection.ordenes,
    AppSection.admin,
  ];

  // Títulos para el AppBar
  final List<String> _titles = [
    'Gestión de Stock',
    'Centro de Órdenes',
    'Administración',
  ];

  @override
  Widget build(BuildContext context) {
    final currentSection = _sections[_currentIndex];

    return Scaffold(
      // 1. Drawer Dinámico: Cambia según la sección activa
      drawer: AppDrawer(currentSection: currentSection),

      // 2. AppBar Global
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),

      // 3. Cuerpo: Mantiene el estado de las páginas
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // Pasamos 'true' para ocultar el AppBar interno de cada página
          StockPage(esNavegacionPrincipal: true),
          OrdenesPage(esNavegacionPrincipal: true),
          // Usamos Clientes como landing de Admin por ahora
          ClientesListPage(esNavegacionPrincipal: true),
        ],
      ),

      // 4. Footer (Barra de Navegación Inferior)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Órdenes',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}