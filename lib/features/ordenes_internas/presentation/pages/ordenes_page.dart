import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/orden_interna_provider.dart';
import '../../data/models/orden_interna_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'orden_detalle_page.dart';
import 'orden_form_page.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
// ✅ IMPORT DEL BUSCADOR
import 'delegates/orden_search_delegate.dart';

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
      context.read<ProductoProvider>().cargarProductos();
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
          // ✅ BOTÓN DE BÚSQUEDA NUEVO
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final listaOrdenes = context.read<OrdenInternaProvider>().ordenes;
              showSearch(
                  context: context,
                  delegate: OrdenSearchDelegate(listaOrdenes)
              );
            },
          ),
          // Switch de filtro propio
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
          // FILTROS CHIPS
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

          // LISTA
          Expanded(
            child: Consumer<OrdenInternaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                final filtradas = provider.ordenes.where((d) {
                  bool pasaEstado = true;
                  if (_filtroEstado == 'solicitado') pasaEstado = d.orden.estado == 'solicitado' || d.orden.estado == 'pendiente';
                  else if (_filtroEstado == 'aprobada') pasaEstado = d.orden.estado == 'aprobada' || d.orden.estado == 'en_proceso';
                  else if (_filtroEstado == 'entregado') pasaEstado = d.orden.estado == 'entregado' || d.orden.estado == 'finalizado' || d.orden.estado == 'completada';

                  bool pasaUsuario = true;
                  if (_soloMisPedidos && user != null) {
                    pasaUsuario = d.orden.solicitanteNombre == user.nombre;
                  }
                  return pasaEstado && pasaUsuario;
                }).toList();

                if (filtradas.isEmpty) {
                  return const Center(child: Text("No hay órdenes con este criterio"));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.cargarOrdenes();
                    if(mounted) context.read<ProductoProvider>().cargarProductos();
                  },
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
    if (orden.estado == 'entregado') colorEstado = Colors.green;

    final progreso = detalle.progresoGeneral;

    // ✅ CORRECCIÓN CL-CL:
    // Limpiamos el ID del cliente por si ya tiene "CL-" o es un UUID
    String rawId = orden.clienteId.replaceAll('CL-', '');
    String clienteCorto = rawId.length > 5 ? rawId.substring(0, 5).toUpperCase() : rawId;

    // Formato Limpio: CL-XXXX | OI-XXXX
    String tituloNomenclatura = "CL-$clienteCorto | ${orden.numero}";

    return Card(
      elevation: 3,
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
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tituloNomenclatura, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: colorEstado.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorEstado)
                    ),
                    child: Text(orden.estado.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorEstado)),
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Cliente y Obra
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(detalle.obraNombre ?? "Obra Sin Asignar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(detalle.clienteRazonSocial, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Solicitante
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text("Solicitante: ", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(orden.solicitanteNombre, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Pie: Fecha y Cantidad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(orden.fechaCreacion), style: const TextStyle(fontSize: 12)),
                  ]),
                  Text("${detalle.cantidadProductos} items • ${orden.prioridad}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),

              if (progreso > 0 && progreso < 1) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progreso, backgroundColor: Colors.grey[200], color: Colors.blue, minHeight: 4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}