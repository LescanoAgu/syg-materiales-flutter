import 'package:flutter/material.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../features/clientes/presentation/pages/clientes_list_page.dart';
import '../constants/app_colors.dart';
import 'app_drawer.dart';

enum AppSection { stock, ordenes, admin }

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<AppSection> _sections = [
    AppSection.stock,
    AppSection.ordenes,
    AppSection.admin,
  ];

  final List<String> _titles = [
    'Gestión de Stock',
    'Centro de Órdenes',
    'Administración',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentSection: _sections[_currentIndex]),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StockPage(esNavegacionPrincipal: true),
          OrdenesPage(esNavegacionPrincipal: true),
          ClientesListPage(esNavegacionPrincipal: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Órdenes'),
          NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}