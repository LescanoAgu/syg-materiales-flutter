import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/acopio_model.dart'; // ✅ Usamos el nuevo modelo
import '../providers/acopio_provider.dart';
import 'proveedor_form_page.dart';

class ProveedorDetallePage extends StatefulWidget {
  final ProveedorModel proveedor;

  const ProveedorDetallePage({super.key, required this.proveedor});

  @override
  State<ProveedorDetallePage> createState() => _ProveedorDetallePageState();
}

class _ProveedorDetallePageState extends State<ProveedorDetallePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargamos los acopios para poder filtrar los de este proveedor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarDatos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.proveedor.nombre),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Información'),
            Tab(text: 'Compras Realizadas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProveedorFormPage(proveedor: widget.proveedor))
            ).then((_) => setState((){})),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final p = widget.proveedor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.store, color: AppColors.primary, size: 40),
            title: Text(p.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text(p.tipo.name.toUpperCase()),
          ),
        ),
        const SizedBox(height: 16),
        _buildDato(Icons.code, 'Código', p.codigo),
        _buildDato(Icons.location_on, 'Dirección', p.direccion),
        _buildDato(Icons.phone, 'Teléfono', p.telefono),
        _buildDato(Icons.email, 'Email', p.email),
        _buildDato(Icons.person, 'Contacto', p.contacto),
      ],
    );
  }

  Widget _buildDato(IconData icon, String label, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(valor, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ),
    );
  }

  Widget _buildHistorialTab() {
    // Filtramos los acopios donde este proveedor sea el origen
    return Consumer<AcopioProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        // Buscamos acopios vinculados a este proveedor (por ID o código)
        final compras = provider.acopios.where((a) =>
        a.proveedorId == widget.proveedor.id ||
            a.proveedorId == widget.proveedor.codigo
        ).toList();

        if (compras.isEmpty) {
          return const Center(child: Text("No hay compras registradas a este proveedor"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: compras.length,
          itemBuilder: (context, index) {
            final acopio = compras[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.receipt, color: Colors.white),
                ),
                title: Text(acopio.etiqueta),
                subtitle: Text("Factura: ${acopio.numeroFactura}\n${ArgFormats.fecha(acopio.fechaCompra)}"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                // Aquí se podría navegar al detalle de la factura si lo deseamos
              ),
            );
          },
        );
      },
    );
  }
}