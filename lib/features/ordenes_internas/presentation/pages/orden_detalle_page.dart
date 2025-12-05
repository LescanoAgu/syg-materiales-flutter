import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart'; // ✅ Importamos los roles
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/usuarios/presentation/providers/usuarios_provider.dart';

// Widgets y Páginas
import '../widgets/orden_aprobacion_dialog.dart';
import '../widgets/remitos_historicos_dialog.dart';
import 'orden_despacho_page.dart';

class OrdenDetallePage extends StatefulWidget {
  final OrdenInternaDetalle ordenResumen;
  const OrdenDetallePage({super.key, required this.ordenResumen});

  @override
  State<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends State<OrdenDetallePage> {
  bool _cargandoItems = true;
  late OrdenInternaDetalle _ordenCompleta;

  @override
  void initState() {
    super.initState();
    _ordenCompleta = widget.ordenResumen;
    _cargarDetallesCompletos();
  }

  Future<void> _cargarDetallesCompletos() async {
    if (widget.ordenResumen.orden.id == null) {
      setState(() => _cargandoItems = false);
      return;
    }
    final detalle = await context.read<OrdenInternaProvider>()
        .cargarDetalleOrden(widget.ordenResumen.orden.id!);

    final orgId = context.read<AuthProvider>().usuario?.organizationId;
    if (orgId != null) {
      context.read<UsuariosProvider>().cargarUsuarios(orgId);
    }

    if (mounted && detalle != null) {
      setState(() {
        _ordenCompleta = detalle;
        _cargandoItems = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orden = _ordenCompleta.orden;
    final color = _getEstadoColor(orden.estado);
    final usuario = context.watch<AuthProvider>().usuario;

    // ✅ CAMBIO CLAVE: Usamos el sistema de permisos.
    // Como quitaste 'aprobarOrden' del rol Jefe de Obra en AppRoles,
    // esta variable será TRUE solo para Admin (o quien tenga permiso especial).
    final puedeAprobar = usuario?.tienePermiso(AppRoles.aprobarOrden) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orden ${orden.numero}'),
        actions: [
          // Historial de remitos solo si ya hay movimiento
          if (orden.estado == 'en_curso' || orden.estado == 'entregado')
            IconButton(
              icon: const Icon(Icons.history_edu),
              tooltip: 'Ver Remitos Históricos',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RemitosHistoricosDialog(
                    ordenId: orden.id!,
                    ordenDetalle: _ordenCompleta,
                  ),
                );
              },
            ),

          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Orden',
            onPressed: () => PdfService().generarOrdenInterna(_ordenCompleta),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDetallesCompletos,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderEstado(orden, color, puedeAprobar),
            const SizedBox(height: 20),
            _buildSeccionInvolucrados(orden),
            const SizedBox(height: 20),
            _buildSeccionInfo(orden),
            const SizedBox(height: 20),
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 10),
            if (_cargandoItems)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else
              ..._ordenCompleta.items.map((item) => _buildProductoItem(item)),

            // Si ya está entregado o en curso, mostrar última firma si existe
            if ((orden.estado == 'entregado' || orden.estado == 'en_curso') && orden.firmaUrl != null)
              _buildFirmaVisual(orden.firmaUrl!),

            const SizedBox(height: 40),

            if (orden.estado == 'aprobado' || orden.estado == 'en_curso')
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(child: Text("Para entregar material, diríjase al menú 'Área de Despacho'.", style: TextStyle(fontSize: 13))),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderEstado(OrdenInterna orden, Color color, bool puedeAprobar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color)
      ),
      child: Row(
        children: [
          Icon(_getEstadoIcon(orden.estado), color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orden.estado.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                if(orden.prioridad == 'urgente')
                  const Text("PRIORIDAD URGENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // ✅ EL BOTÓN SOLO APARECE SI TIENE EL PERMISO
          if (orden.estado == 'solicitado' && puedeAprobar)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => _aprobarOrden(context, orden),
              child: const Text("APROBAR"),
            )
        ],
      ),
    );
  }

  Widget _buildSeccionInvolucrados(OrdenInterna orden) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Equipo Vinculado", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (orden.usuariosEtiquetados.isEmpty)
            const Text("Nadie etiquetado.", style: TextStyle(color: Colors.grey, fontSize: 13))
          else
            Wrap(
              spacing: 8,
              children: orden.usuariosEtiquetados.map((uid) => Chip(label: Text(uid.substring(0, 4)))).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSeccionInfo(OrdenInterna orden) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDato("Cliente", _ordenCompleta.clienteRazonSocial),
            const Divider(),
            _buildDato("Obra", _ordenCompleta.obraNombre ?? "N/A"),
            const Divider(),
            _buildDato("Notas", orden.observacionesCliente ?? "-"),
          ],
        ),
      ),
    );
  }

  Widget _buildDato(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildProductoItem(OrdenItemDetalle d) {
    double entregado = d.item.cantidadEntregada;
    double total = d.cantidadFinal;
    bool completo = entregado >= total;
    double porcentaje = total > 0 ? (entregado/total).clamp(0.0, 1.0) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(d.productoNombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
                value: porcentaje,
                backgroundColor: Colors.grey[200],
                color: completo ? Colors.green : Colors.orange
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entregado.toStringAsFixed(0)} / ${total.toStringAsFixed(0)} ${d.unidadBase}'),
                Text(d.item.origen.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Icon(completo ? Icons.check_circle : Icons.timelapse, color: completo ? Colors.green : Colors.grey),
      ),
    );
  }

  Widget _buildFirmaVisual(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          const Text("Última Firma Registrada", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.white),
            height: 120,
            width: double.infinity,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (c,e,s) => const Center(child: Text("Error cargando firma")),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoEtiquetar() {
    showDialog(context: context, builder: (ctx) => const AlertDialog(title: Text("Próximamente")));
  }

  void _aprobarOrden(BuildContext context, OrdenInterna orden) async {
    final itemsConfiguradosMap = await showDialog<Map<String, Map<String, dynamic>>>(
      context: context,
      builder: (_) => OrdenAprobacionDialog(items: _ordenCompleta.items.map((e) => e.item).toList()),
    );

    if (itemsConfiguradosMap != null && mounted) {
      final user = context.read<AuthProvider>().usuario;
      if (user == null) return;

      final exito = await context.read<OrdenInternaProvider>().aprobarOrden(
        ordenId: orden.id!,
        itemsOriginales: _ordenCompleta.items.map((e) => e.item).toList(),
        logistica: itemsConfiguradosMap,
        usuarioId: user.uid,
      );

      if (exito) _cargarDetallesCompletos();
    }
  }

  Color _getEstadoColor(String estado) {
    if (estado == 'entregado') return Colors.green;
    if (estado == 'aprobado') return Colors.blue;
    if (estado == 'en_curso') return Colors.orange;
    return Colors.grey;
  }

  IconData _getEstadoIcon(String estado) {
    if (estado == 'entregado') return Icons.check_circle;
    if (estado == 'en_curso') return Icons.local_shipping;
    if (estado == 'aprobado') return Icons.thumb_up;
    return Icons.assignment;
  }
}