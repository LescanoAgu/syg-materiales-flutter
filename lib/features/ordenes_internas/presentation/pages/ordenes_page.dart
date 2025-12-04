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
  // Filtros
  bool _soloMisPedidos = false;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await context.read<OrdenInternaProvider>().cargarOrdenes();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final bool mostrarAppBar = !widget.esNavegacionPrincipal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: mostrarAppBar
          ? AppBar(title: const Text("Gestión de Pedidos"))
          : null,
      floatingActionButton: mostrarAppBar
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("NUEVA SOLICITUD"),
        backgroundColor: AppColors.primary,
        onPressed: () => _navegarFormulario(context),
      )
          : null,
      body: Column(
        children: [
          // --- HEADER DE FILTROS CON BOTÓN DE RECARGA ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de Recarga + Título
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: _cargarDatos, // ✅ ¡Botón Mágico!
                          tooltip: "Actualizar lista",
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Text("Filtrar listado:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),

                    FilterChip(
                      label: const Text('👤 Solo Mis Pedidos'),
                      selected: _soloMisPedidos,
                      onSelected: (v) => setState(() => _soloMisPedidos = v),
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                          color: _soloMisPedidos ? AppColors.primary : Colors.black,
                          fontWeight: _soloMisPedidos ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildEstadoChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _buildEstadoChip('⏳ Pendientes', 'solicitado', color: Colors.orange),
                      const SizedBox(width: 8),
                      _buildEstadoChip('🚚 En Curso', 'en_curso', color: Colors.blue),
                      const SizedBox(width: 8),
                      _buildEstadoChip('✅ Finalizados', 'entregado', color: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- LISTA DE ÓRDENES CON PULL-TO-REFRESH ---
          Expanded(
            child: Consumer<OrdenInternaProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                List<OrdenInternaDetalle> lista = provider.ordenes;

                if (_soloMisPedidos && usuario != null) {
                  lista = lista.where((o) => o.orden.solicitanteNombre == usuario.nombre).toList();
                }

                if (_filtroEstado != 'todos') {
                  lista = lista.where((o) => o.orden.estado == _filtroEstado).toList();
                }

                if (lista.isEmpty) {
                  return _buildEmptyState();
                }

                // ✅ RefreshIndicator permite deslizar hacia abajo para recargar
                return RefreshIndicator(
                  onRefresh: _cargarDatos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80, left: 16, right: 16),
                    itemCount: lista.length,
                    itemBuilder: (ctx, i) => _buildOrdenCard(lista[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // Envuelto en ListView para que funcione el RefreshIndicator aun estando vacío
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: const Center(child: Text("No hay órdenes (Desliza para actualizar)", style: TextStyle(color: Colors.grey))),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String label, String value, {Color? color}) {
    final selected = _filtroEstado == value;
    final activeColor = color ?? Colors.grey[800];
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _filtroEstado = v ? value : 'todos'),
      backgroundColor: Colors.white,
      selectedColor: activeColor?.withOpacity(0.1),
      labelStyle: TextStyle(
          color: selected ? activeColor : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle detalle) {
    final orden = detalle.orden;
    final bool esUrgente = orden.prioridad == 'urgente';

    Color bordeColor = Colors.grey;
    if (orden.estado == 'solicitado') bordeColor = Colors.orange;
    if (orden.estado == 'en_curso') bordeColor = Colors.blue;
    if (orden.estado == 'entregado') bordeColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrdenDetallePage(ordenResumen: detalle))
          ).then((_) => _cargarDatos()); // Recargar al volver
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: bordeColor, width: 5)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Orden #${orden.numero}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (esUrgente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                      child: const Text("URGENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                    )
                  else
                    Text(orden.estado.toUpperCase(), style: TextStyle(color: bordeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),

              const SizedBox(height: 8),

              if (orden.titulo != null && orden.titulo!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(orden.titulo!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),

              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detalle.obraNombre ?? "Obra sin nombre",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  detalle.clienteRazonSocial,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${detalle.cantidadProductos} items", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Por: ${orden.solicitanteNombre}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _navegarFormulario(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdenFormPage())
    ).then((_) => _cargarDatos());
  }
}