import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/billetera_acopio_model.dart';
import '../providers/acopio_provider.dart';
import 'acopio_movimiento_page.dart';
import 'facturas_list_page.dart';
import 'acopio_traspaso_page.dart';
import 'movimiento_lote_page.dart';
import 'acopio_detalle_page.dart'; // ✅ Importante para navegar

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
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Billetera de Materiales'),
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
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Por Cliente'),
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
            hintText: 'Buscar cliente o producto...',
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
            Text('Items con Saldo: ${prov.totalAcopios}'),
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
        if (prov.acopios.isEmpty) return const Center(child: Text('No hay saldos positivos'));

        return ListView.builder(
          itemCount: prov.acopios.length,
          itemBuilder: (c, i) => _BilleteraCard(billetera: prov.acopios[i]),
        );
      },
    );
  }

  Widget _buildVistaPorCliente() => const Center(child: Text("Vista Agrupada (Próximamente)"));
}

class _BilleteraCard extends StatelessWidget {
  final BilleteraAcopio billetera;
  const _BilleteraCard({required this.billetera});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(billetera.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${billetera.clienteNombre}'),
            if (billetera.cantidadEnDepositoPropio > 0)
              Text('En S&G: ${billetera.cantidadEnDepositoPropio}', style: const TextStyle(color: Colors.green, fontSize: 12)),
            if (billetera.cantidadEnProveedores.isNotEmpty)
              Text('En Proveedores: ${_sumarProveedores(billetera.cantidadEnProveedores)}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        trailing: Text(
            '${billetera.saldoTotal}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)
        ),
        isThreeLine: true,
        // ✅ NAVEGACIÓN AGREGADA
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AcopioDetallePage(billetera: billetera)),
          );
        },
      ),
    );
  }

  double _sumarProveedores(Map<String, double> provs) {
    return provs.values.fold(0, (sum, val) => sum + val);
  }
}