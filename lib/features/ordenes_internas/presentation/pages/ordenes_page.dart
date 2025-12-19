import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'orden_detalle_page.dart';
import 'orden_form_page.dart';

class OrdenesPage extends StatefulWidget {
  final bool esNavegacionPrincipal;
  const OrdenesPage({super.key, this.esNavegacionPrincipal = false});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  String _filtroEstado = 'todos';
  bool _soloMisPedidos = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().usuario;
    final bool mostrarAppBar = !widget.esNavegacionPrincipal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: mostrarAppBar
          ? AppBar(
        title: const Text("Órdenes de Pedido"),
        backgroundColor: AppColors.primary,
        actions: [
          Row(
            children: [
              const Text("Solo mías", style: TextStyle(fontSize: 12)),
              Switch(
                value: _soloMisPedidos,
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
                onChanged: (v) => setState(() => _soloMisPedidos = v),
              )
            ],
          )
        ],
      )
          : null,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Pendientes', 'solicitado'),
                const SizedBox(width: 8),
                _buildFilterChip('En Proceso', 'aprobada'),
                const SizedBox(width: 8),
                _buildFilterChip('Finalizadas', 'entregado'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<OrdenInternaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                final filtradas = provider.ordenes.where((d) {
                  bool pasaEstado = true;
                  if (_filtroEstado == 'solicitado') pasaEstado = d.orden.estado == 'solicitado' || d.orden.estado == 'pendiente';
                  else if (_filtroEstado == 'aprobada') pasaEstado = d.orden.estado == 'aprobada' || d.orden.estado == 'en_proceso';
                  else if (_filtroEstado == 'entregado') pasaEstado = d.orden.estado == 'entregado' || d.orden.estado == 'finalizado';

                  bool pasaUsuario = true;
                  if (_soloMisPedidos && user != null) {
                    pasaUsuario = d.orden.solicitanteNombre == user.nombre;
                  }
                  return pasaEstado && pasaUsuario;
                }).toList();

                if (filtradas.isEmpty) return const Center(child: Text("No hay órdenes con este criterio"));

                return RefreshIndicator(
                  onRefresh: () => provider.cargarOrdenes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
                    itemCount: filtradas.length,
                    itemBuilder: (ctx, i) => _buildOrdenCard(filtradas[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Nuevo Pedido"),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdenFormPage()))
            .then((_) => context.read<OrdenInternaProvider>().cargarOrdenes()),
      ),
    );
  }

  Widget _buildFilterChip(String label, String valor) {
    final selected = _filtroEstado == valor;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _filtroEstado = valor),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
          color: selected ? AppColors.primary : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle detalle) {
    final orden = detalle.orden;
    Color colorEstado = Colors.orange;
    if (orden.estado == 'aprobada') colorEstado = Colors.blue;
    if (orden.estado == 'en_proceso') colorEstado = Colors.purple;
    if (orden.estado == 'entregado') colorEstado = Colors.green;

    // Progreso
    final progreso = detalle.progresoGeneral;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrdenDetallePage(orden: orden)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("#${orden.numero}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorEstado)
                    ),
                    child: Text(
                        orden.estado.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorEstado)
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(detalle.obraNombre ?? "Obra sin nombre", style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(detalle.clienteRazonSocial, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),

              // === BARRA DE PROGRESO ===
              if (progreso > 0 && progreso < 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Avance de Entrega", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    Text("${(progreso * 100).toInt()}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progreso,
                    backgroundColor: Colors.grey[200],
                    color: Colors.blue,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chips de Origen
                  if (orden.esRetiroAcopio || orden.origen == OrigenAbastecimiento.acopio_cliente)
                    const Chip(label: Text("Acopio", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.purple, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)
                  else if (orden.origen == OrigenAbastecimiento.compra_proveedor)
                    const Chip(label: Text("Compra Directa", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),

                  Text("${detalle.cantidadProductos} items"),
                  Text(orden.prioridad.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}