import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../reportes/data/services/pdf_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/usuarios/presentation/providers/usuarios_provider.dart';

import '../widgets/orden_despacho_dialog.dart';
import '../widgets/orden_aprobacion_dialog.dart';
// ✅ Importamos el widget de firma que acabamos de crear
import '../widgets/firma_digital_dialog.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orden ${orden.numero}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Orden',
            onPressed: () => PdfService().generarOrdenInterna(_ordenCompleta),
          ),
        ],
      ),
      floatingActionButton: _buildFabAction(orden),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderEstado(orden, color),
            const SizedBox(height: 20),
            _buildSeccionInvolucrados(orden),
            const SizedBox(height: 20),
            _buildSeccionInfo(orden),
            const SizedBox(height: 20),
            const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            if (_cargandoItems)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else
              ..._ordenCompleta.items.map((item) => _buildProductoItem(item)),

            if (orden.estado == 'entregado' && orden.firmaUrl != null)
              _buildFirmaVisual(orden.firmaUrl!),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget? _buildFabAction(OrdenInterna orden) {
    if (orden.estado == 'solicitado') return null;

    if (orden.estado == 'aprobado' || (orden.estado == 'en_curso' && orden.porcentajeAvance < 1.0)) {
      return FloatingActionButton.extended(
        icon: const Icon(Icons.local_shipping),
        label: const Text("DESPACHAR MATERIAL"),
        backgroundColor: AppColors.primary,
        onPressed: _abrirDespacho,
      );
    }

    if (orden.estado == 'en_curso') {
      return FloatingActionButton.extended(
        // ✅ FIX: Usamos Icons.draw porque Icons.signature no existe
        icon: const Icon(Icons.draw),
        label: const Text("FIRMAR Y ENTREGAR"),
        backgroundColor: Colors.green,
        onPressed: _abrirFirma,
      );
    }

    return null;
  }

  Widget _buildHeaderEstado(OrdenInterna orden, Color color) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orden.estado.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              if(orden.prioridad == 'urgente')
                const Text("PRIORIDAD URGENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const Spacer(),
          if (orden.estado == 'solicitado')
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Equipo Vinculado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text("Etiquetar"),
              onPressed: _abrirDialogoEtiquetar,
            )
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: orden.usuariosEtiquetados.isEmpty
              ? const Text("Nadie etiquetado aún.", style: TextStyle(color: Colors.grey, fontSize: 13))
              : Wrap(
            spacing: 8,
            children: orden.usuariosEtiquetados.map((uid) {
              final usuarios = context.watch<UsuariosProvider>().usuarios;
              // Búsqueda segura
              String nombre = "Usuario";
              try {
                final u = usuarios.firstWhere((u) => u.uid == uid);
                nombre = u.nombre;
              } catch (_) {}

              return Chip(
                avatar: CircleAvatar(child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : "?")),
                label: Text(nombre),
                backgroundColor: Colors.blue.shade50,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ... (Resto de métodos visuales como _buildSeccionInfo, _buildDato, _buildProductoItem, _buildFirmaVisual)
  // Puedes dejar los que tenías, solo asegúrate de que _buildFirmaVisual use Image.network

  Widget _buildSeccionInfo(OrdenInterna orden) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDato("Cliente", _ordenCompleta.clienteRazonSocial),
            const Divider(),
            _buildDato("Obra", _ordenCompleta.obraNombre ?? "N/A"),
            const Divider(),
            _buildDato("Solicitante", orden.solicitanteNombre),
            if (orden.observacionesCliente != null) ...[
              const Divider(),
              _buildDato("Notas", orden.observacionesCliente!),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDato(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
        Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildProductoItem(OrdenItemDetalle d) {
    double entregado = d.item.cantidadEntregada;
    double total = d.cantidadFinal;
    bool completo = entregado >= total;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(d.productoNombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: total > 0 ? entregado/total : 0, backgroundColor: Colors.grey[200], color: completo ? Colors.green : Colors.orange),
            const SizedBox(height: 4),
            Text('${entregado.toStringAsFixed(1)} / ${total.toStringAsFixed(1)} ${d.unidadBase}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
        trailing: Icon(completo ? Icons.check_circle : Icons.timelapse, color: completo ? Colors.green : Colors.grey),
      ),
    );
  }

  Widget _buildFirmaVisual(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text("Comprobante de Entrega", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), color: Colors.white),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ],
    );
  }

  // --- ACCIONES ---

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
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Despacho registrado")));
          _preguntarImprimirRemito(items, user.nombre);
        }
      }
    }
  }

  void _preguntarImprimirRemito(List<Map<String, dynamic>> items, String nombreResponsable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🖨️ Remito de Entrega"),
        content: const Text("¿Generar PDF para que el chofer lleve a la obra?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Ahora no")),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text("IMPRIMIR"),
            onPressed: () async {
              Navigator.pop(ctx);
              await PdfService().generarRemitoDespacho(
                ordenDetalle: _ordenCompleta,
                itemsDespachados: items,
                nombreResponsable: nombreResponsable,
              );
            },
          )
        ],
      ),
    );
  }

  void _abrirFirma() async {
    final firmaBytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const FirmaDigitalDialog(),
    );

    if (firmaBytes != null && mounted) {
      // ✅ FIX: Llama al método que ahora SÍ existe en el Provider
      final exito = await context.read<OrdenInternaProvider>().confirmarEntrega(
        _ordenCompleta.orden.id!,
        firmaBytes,
      );

      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Entrega Finalizada y Firmada"), backgroundColor: Colors.green));
        _cargarDetallesCompletos();
      }
    }
  }

  void _abrirDialogoEtiquetar() {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Etiquetar Personal"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Consumer<UsuariosProvider>(
                builder: (context, provider, _) {
                  // Filtra usuarios activos
                  final usuarios = provider.usuarios.where((u) => u.estado == 'activo').toList();

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (c, i) {
                      final u = usuarios[i];
                      final estaEtiquetado = _ordenCompleta.orden.usuariosEtiquetados.contains(u.uid);

                      return CheckboxListTile(
                        title: Text(u.nombre),
                        subtitle: Text(u.rol),
                        value: estaEtiquetado,
                        onChanged: (val) async {
                          Navigator.pop(ctx); // Cerramos primero para evitar conflictos visuales
                          if (val == true) {
                            // ✅ FIX: Llama al método que ahora SÍ existe
                            await context.read<OrdenInternaProvider>().agregarEtiqueta(_ordenCompleta.orden.id!, u.uid);
                          }
                          _cargarDetallesCompletos();
                        },
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))
            ],
          );
        }
    );
  }

  void _aprobarOrden(BuildContext context, OrdenInterna orden) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => OrdenAprobacionDialog(items: _ordenCompleta.items),
    );

    if (resultado != null && mounted) {
      final user = context.read<AuthProvider>().usuario;
      final exito = await context.read<OrdenInternaProvider>().aprobarOrden(
        ordenId: orden.id!,
        configuracionItems: resultado['configuracionItems'],
        proveedorId: resultado['proveedorId'],
        usuarioId: user!.uid,
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