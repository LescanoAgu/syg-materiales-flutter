import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/acopio_model.dart';
import '../providers/acopio_provider.dart';
import 'acopio_movimiento_page.dart';
import 'facturas_list_page.dart';
import 'acopio_traspaso_page.dart';
import 'acopio_historial_page.dart';
import 'movimiento_lote_page.dart';

class AcopiosListPage extends StatefulWidget {
  const AcopiosListPage({super.key});
  @override
  State<AcopiosListPage> createState() => _AcopiosListPageState();
}

class _AcopiosListPageState extends State<AcopiosListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarTodo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Acopios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FacturasListPage()),
              ).then((_) => context.read<AcopioProvider>().cargarTodo());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AcopioProvider>().refrescar(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Por Cliente'),
            Tab(text: 'Por Proveedor'),
            Tab(text: 'Reservas S&G'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildEstadisticas(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVistaGeneral(),
                _buildVistaPorCliente(),
                _buildVistaPorProveedor(),
                _buildVistaReservas(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'traspaso',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AcopioTraspasoPage()))
                  .then((_) => context.read<AcopioProvider>().cargarTodo());
            },
            backgroundColor: AppColors.warning,
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'lote',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MovimientoLotePage()))
                  .then((_) => context.read<AcopioProvider>().cargarTodo());
            },
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.playlist_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'movimiento',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AcopioMovimientoPage()))
                  .then((_) => context.read<AcopioProvider>().cargarTodo());
            },
            icon: const Icon(Icons.add),
            label: const Text('MOVIMIENTO'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
            hintText: 'Buscar...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<AcopioProvider>().limpiarFiltros();
                }
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
        ),
        onChanged: (v) => context.read<AcopioProvider>().buscarPorProducto(v),
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<AcopioProvider>(
      builder: (ctx, prov, _) => Container(
        padding: const EdgeInsets.all(8),
        color: Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Total: ${prov.totalAcopios}'),
            Text('Clientes: ${prov.totalClientes}'),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaGeneral() {
    return Consumer<AcopioProvider>(
      builder: (ctx, prov, _) {
        if (prov.isLoading) return const Center(child: CircularProgressIndicator());
        if (prov.acopios.isEmpty) return const Center(child: Text('No hay acopios'));
        return ListView.builder(
          itemCount: prov.acopios.length,
          itemBuilder: (c, i) => _AcopioCard(acopioDetalle: prov.acopios[i]),
        );
      },
    );
  }

  // Placeholders para las otras vistas para ahorrar espacio y evitar errores
  Widget _buildVistaPorCliente() => const Center(child: Text("Vista por Cliente"));
  Widget _buildVistaPorProveedor() => const Center(child: Text("Vista por Proveedor"));
  Widget _buildVistaReservas() => const Center(child: Text("Reservas"));
}

class _AcopioCard extends StatelessWidget {
  final AcopioDetalle acopioDetalle;
  const _AcopioCard({required this.acopioDetalle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(acopioDetalle.productoNombre),
        subtitle: Text('${acopioDetalle.clienteRazonSocial} - ${acopioDetalle.proveedorNombre}'),
        trailing: Text('${acopioDetalle.cantidadFormateada} ${acopioDetalle.unidadBase}'),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AcopioHistorialPage(acopioDetalle: acopioDetalle)));
        },
      ),
    );
  }
}