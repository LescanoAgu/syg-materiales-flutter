import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
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
  List<MovimientoAcopioModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    // Usamos el ID o el Código como identificador
    final id = widget.proveedor.id ?? widget.proveedor.codigo;
    final movs = await context.read<AcopioProvider>().obtenerMovimientosProveedor(id);

    if (mounted) {
      setState(() {
        _movimientos = movs;
        _isLoading = false;
      });
    }
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
            Tab(text: 'Historial de Retiros'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProveedorFormPage(proveedor: widget.proveedor))
            ).then((_) => setState((){})), // Recargar simple
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_movimientos.isEmpty) {
      return const Center(child: Text("No hay movimientos registrados para este proveedor"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movimientos.length,
      itemBuilder: (context, index) {
        final m = _movimientos[index];
        final esSalida = m.cantidad < 0; // En lógica de billetera, negativo suele ser consumo/salida

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: esSalida ? Colors.orange[100] : Colors.green[100],
              child: Icon(esSalida ? Icons.arrow_upward : Icons.arrow_downward,
                  color: esSalida ? Colors.orange : Colors.green),
            ),
            title: Text(m.productoId), // O productoNombre si el modelo lo tiene lleno
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ArgFormats.fechaHora(m.createdAt)),
                if (m.referencia != null) Text("Ref: ${m.referencia}", style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Text(
              '${m.cantidad.abs()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}