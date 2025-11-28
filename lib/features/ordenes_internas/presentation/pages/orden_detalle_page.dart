import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/data/models/usuario_model.dart';
import '../widgets/asignar_chofer_dialog.dart';
import '../widgets/orden_despacho_dialog.dart';
import '../widgets/orden_aprobacion_dialog.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orden ${orden.numero}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir PDF',
            onPressed: () => PdfService().generarRemitoOrden(_ordenCompleta),
          ),
        ],
      ),
      floatingActionButton: (orden.estado == 'aprobado' || orden.estado == 'en_curso')
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.local_shipping),
        label: const Text("DESPACHAR"),
        backgroundColor: AppColors.primary,
        onPressed: _abrirDespacho,
      )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderEstado(orden, color),
            const SizedBox(height: 20),

            if (orden.estado != 'solicitado' && orden.estado != 'rechazado')
              _buildSeccionResponsable(context, orden),

            const SizedBox(height: 20),
            _buildSeccionInfo(orden),
            const SizedBox(height: 20),
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),

            if (_cargandoItems) const Center(child: CircularProgressIndicator())
            else ..._ordenCompleta.items.map((item) => _buildProductoItem(item)),

            const SizedBox(height: 30),
            if (orden.estado == 'solicitado') _buildBotonesAccion(context, orden),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA ---

  void _abrirDespacho() async {
    final items = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => OrdenDespachoDialog(ordenDetalle: _ordenCompleta),
    );

    if (items != null && items.isNotEmpty && mounted) {
      final user = context.read<AuthProvider>().usuario;
      final provider = context.read<OrdenInternaProvider>();

      final exito = await provider.registrarDespacho(
        ordenId: _ordenCompleta.orden.id!,
        ordenNumero: _ordenCompleta.orden.numero,
        obraId: _ordenCompleta.orden.obraId,
        usuarioId: user!.uid,
        usuarioNombre: user.nombre,
        items: items,
      );

      if (exito) {
        _cargarDetallesCompletos();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Despacho registrado")));
      } else {
        if(mounted && provider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage!), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _aprobarOrden(BuildContext context, OrdenInterna orden) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const OrdenAprobacionDialog(),
    );

    if (resultado != null && mounted) {
      final user = context.read<AuthProvider>().usuario;
      final provider = context.read<OrdenInternaProvider>();

      final exito = await provider.aprobarOrden(
        ordenId: orden.id!,
        fuente: resultado['fuente'],
        proveedorId: resultado['proveedorId'],
        usuarioId: user!.uid,
      );

      if (exito) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Orden Aprobada"), backgroundColor: Colors.green));
        _cargarDetallesCompletos();
      } else {
        if(mounted && provider.errorMessage != null) {
          showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("⚠️ No se pudo aprobar"),
                content: Text(provider.errorMessage!),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Entendido"))],
              )
          );
        }
      }
    }
  }

  void _asignarChofer(BuildContext context, OrdenInterna orden) async {
    final UsuarioModel? seleccionado = await showDialog(
      context: context,
      builder: (_) => const AsignarChoferDialog(),
    );

    if (seleccionado != null && mounted) {
      final exito = await context.read<OrdenInternaProvider>().asignarResponsable(
        ordenId: orden.id!,
        usuarioId: seleccionado.uid,
        usuarioNombre: seleccionado.nombre,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Asignado a ${seleccionado.nombre}")));
        _cargarDetallesCompletos();
      }
    }
  }

  // --- WIDGETS ---

  Widget _buildBotonesAccion(BuildContext context, OrdenInterna orden) {
    return Row(
      children: [
        Expanded(
            child: OutlinedButton(
              onPressed: (){
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rechazo aún no implementado")));
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("RECHAZAR"),
            )
        ),
        const SizedBox(width: 16),
        Expanded(
            child: ElevatedButton(
              onPressed: () => _aprobarOrden(context, orden),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("APROBAR"),
            )
        ),
      ],
    );
  }

  Widget _buildSeccionResponsable(BuildContext context, OrdenInterna orden) {
    bool tieneResponsable = orden.responsableEntregaNombre != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.local_shipping, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("RESPONSABLE DE ENTREGA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(tieneResponsable ? orden.responsableEntregaNombre! : "Sin asignar", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (!orden.esFinal)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _asignarChofer(context, orden), tooltip: "Asignar Chofer")
        ],
      ),
    );
  }

  Widget _buildProductoItem(OrdenItemDetalle d) {
    double entregado = d.item.cantidadEntregada;
    double total = d.cantidadFinal;
    bool completo = entregado >= total;

    return Card(
      child: ListTile(
        title: Text(d.productoNombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solicitado: ${total.toStringAsFixed(1)} ${d.unidadBase}'),
            Text('Entregado: ${entregado.toStringAsFixed(1)}', style: TextStyle(color: completo ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Icon(completo ? Icons.check_circle : Icons.timelapse, color: completo ? Colors.green : Colors.orange),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    if (estado == 'aprobado') return Colors.blue;
    if (estado == 'en_curso') return Colors.orange;
    if (estado == 'finalizado') return Colors.green;
    return Colors.grey;
  }

  IconData _getEstadoIcon(String estado) {
    if (estado == 'finalizado') return Icons.check_circle;
    if (estado == 'en_curso') return Icons.local_shipping;
    return Icons.info;
  }

  Widget _buildHeaderEstado(OrdenInterna orden, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Row(children: [Icon(_getEstadoIcon(orden.estado), color: color), const SizedBox(width: 10), Text(orden.estado.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20))]),
    );
  }

  Widget _buildSeccionInfo(OrdenInterna orden) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Cliente: ${_ordenCompleta.clienteRazonSocial}'),
      const SizedBox(height: 8),
      Text('Obra: ${_ordenCompleta.obraNombre ?? "N/A"}'),
      const SizedBox(height: 8),
      Text('Fuente: ${orden.fuente?.toUpperCase() ?? "Pendiente"}'),
    ])));
  }
}