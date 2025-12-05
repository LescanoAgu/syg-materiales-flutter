import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de tener url_launcher en pubspec
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cliente_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart'; // Para cargar obras
import '../../../obras/data/models/obra_model.dart';
import '../../../ordenes_internas/data/models/orden_interna_model.dart';
import '../../../ordenes_internas/data/repositories/orden_interna_repository.dart';
import 'cliente_form_page.dart';

class ClienteDetallePage extends StatefulWidget {
  final ClienteModel cliente;
  const ClienteDetallePage({super.key, required this.cliente});

  @override
  State<ClienteDetallePage> createState() => _ClienteDetallePageState();
}

class _ClienteDetallePageState extends State<ClienteDetallePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ClienteModel _cliente;

  // Futures para datos asíncronos
  late Future<List<ObraModel>> _obrasFuture;
  late Future<List<OrdenInternaDetalle>> _historialFuture;

  @override
  void initState() {
    super.initState();
    _cliente = widget.cliente;
    _tabController = TabController(length: 3, vsync: this);
    _recargarDatos();
  }

  void _recargarDatos() {
    // 1. Cargar Obras
    _obrasFuture = Future(() async {
      // Usamos el repo del provider de obras (o el repo directo)
      // Como no expusimos 'obtenerPorCliente' en el provider, lo simulamos filtrando
      // Idealmente: await ObraRepository().obtenerPorCliente(_cliente.codigo);
      final provider = context.read<ObraProvider>();
      await provider.cargarObras(); // Carga todas
      return provider.obras.where((o) => o.clienteId == _cliente.codigo || o.clienteId == _cliente.id).toList();
    });

    // 2. Cargar Historial Pedidos
    _historialFuture = OrdenInternaRepository().getOrdenesPorCliente(_cliente.codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          _cliente.razonSocial[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _cliente.razonSocial,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _cliente.codigo,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClienteFormPage(cliente: _cliente)),
                  );
                  // Actualizar estado al volver (si se editó)
                  // Aquí simplificamos, idealmente recargaríamos desde DB
                },
              )
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: "INFO", icon: Icon(Icons.info_outline, size: 20)),
                Tab(text: "OBRAS", icon: Icon(Icons.business, size: 20)),
                Tab(text: "PEDIDOS", icon: Icon(Icons.history, size: 20)),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabInfo(),
            _buildTabObras(),
            _buildTabHistorial(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: INFORMACIÓN ---
  Widget _buildTabInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle("Datos de Contacto"),
        _buildInfoCard([
          _buildInfoRow(Icons.phone, "Teléfono", _cliente.telefono, isLink: true),
          const Divider(),
          _buildInfoRow(Icons.email, "Email", _cliente.email, isLink: true),
          const Divider(),
          _buildInfoRow(Icons.map, "Dirección", _cliente.direccion),
          const Divider(),
          _buildInfoRow(Icons.location_city, "Localidad", _cliente.localidad),
        ]),

        const SizedBox(height: 20),
        _buildSectionTitle("Datos Fiscales"),
        _buildInfoCard([
          _buildInfoRow(Icons.badge, "CUIT", _cliente.cuitFormateado),
          const Divider(),
          _buildInfoRow(Icons.receipt, "Condición IVA", _cliente.condicionIva),
        ]),

        if (_cliente.observaciones != null && _cliente.observaciones!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionTitle("Observaciones"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_cliente.observaciones!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          )
        ],
      ],
    );
  }

  // --- TAB 2: OBRAS ---
  Widget _buildTabObras() {
    return FutureBuilder<List<ObraModel>>(
      future: _obrasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("Sin obras activas");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) {
            final obra = snapshot.data![i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.engineering, color: AppColors.primary),
                title: Text(obra.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(obra.direccion ?? "Sin dirección"),
                trailing: Chip(
                  label: Text(obra.estado.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: obra.estado == 'activa' ? Colors.green : Colors.grey,
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 3: HISTORIAL ---
  Widget _buildTabHistorial() {
    return FutureBuilder<List<OrdenInternaDetalle>>(
      future: _historialFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState("Sin historial de pedidos");

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (ctx, i) {
            final d = snapshot.data![i];
            return Card(
              child: ListTile(
                title: Text("Orden ${d.orden.numero}"),
                subtitle: Text(ArgFormats.fecha(d.orden.fechaPedido)),
                trailing: Text(
                  d.orden.estado.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: d.orden.estado == 'entregado' ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPERS UI ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value ?? "-",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isLink && value != null ? Colors.blue : Colors.black87,
                    decoration: isLink && value != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (isLink && value != null)
            const Icon(Icons.arrow_outward, size: 16, color: Colors.grey)
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}