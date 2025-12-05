import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/main_layout.dart';
import '../../../../core/enums/app_section.dart';
// Vistas embebidas
import '../../../ordenes_internas/presentation/pages/despachos_list_page.dart';
import '../../../stock/presentation/pages/stock_page.dart'; // Aquí irá el "Super Stock" luego

class PanoleroHomePage extends StatefulWidget {
  const PanoleroHomePage({super.key});

  @override
  State<PanoleroHomePage> createState() => _PanoleroHomePageState();
}

class _PanoleroHomePageState extends State<PanoleroHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pañol S&G'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'POR DESPACHAR', icon: Icon(Icons.local_shipping)),
            Tab(text: 'CONSULTAR STOCK', icon: Icon(Icons.inventory_2)),
          ],
        ),
      ),
      drawer: const AppDrawer(currentSection: AppSection.stock),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Pestaña 1: Lista de Despachos (Lo que tiene que armar)
          // Nota: Reutilizamos DespachosListPage pero quitándole el Scaffold interno luego si queremos
          DespachosListPage(),

          // Pestaña 2: Super Stock (Buscador rápido)
          // Nota: Aquí va StockPage, que luego modificaremos para que sea "Super Stock"
          StockPage(esNavegacionPrincipal: true),
        ],
      ),
    );
  }
}