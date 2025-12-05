// UBICACIÓN: lib/features/ordenes_internas/presentation/pages/orden_despacho_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class OrdenDespachoPage extends StatefulWidget {
  final OrdenInternaDetalle ordenDetalle;

  const OrdenDespachoPage({super.key, required this.ordenDetalle});

  @override
  State<OrdenDespachoPage> createState() => _OrdenDespachoPageState();
}

class _OrdenDespachoPageState extends State<OrdenDespachoPage> {
  final Map<String, TextEditingController> _controllers = {};

  // Controladores de firma
  final SignatureController _firmaAutorizaCtrl = SignatureController(
      penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  final SignatureController _firmaRecibeCtrl = SignatureController(
      penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos controladores solo para items pendientes
    for (var itemDetalle in widget.ordenDetalle.items) {
      if (!itemDetalle.estaCompleto) {
        _controllers[itemDetalle.item.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) c.dispose();
    _firmaAutorizaCtrl.dispose();
    _firmaRecibeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Generar Remito')),
      body: _isSubmitting
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Generando Remito Digital...")]))
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 16),
            _buildListaItems(),
            const SizedBox(height: 24),
            _buildSeccionFirmas(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, size: 28),
                  label: const Text("CONFIRMAR ENTREGA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 4
                  ),
                  onPressed: _procesarDespacho,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final orden = widget.ordenDetalle.orden;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("DESTINO", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(orden.numero, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.ordenDetalle.obraNombre ?? "Sin obra", style: AppTextStyles.h2),
          Text(widget.ordenDetalle.clienteRazonSocial, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildListaItems() {
    final pendientes = widget.ordenDetalle.items.where((i) => !i.estaCompleto).toList();

    if (pendientes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: Text("✅ Orden Completada. No hay items pendientes.")),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Materiales a entregar hoy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendientes.length,
            separatorBuilder: (_,__) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final d = pendientes[i];
              final pendiente = d.cantidadFinal - d.item.cantidadEntregada;
              final controller = _controllers[d.item.id];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Info Item
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Faltan entregar: ${pendiente.toStringAsFixed(1)} ${d.unidadBase}",
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text("Origen: ${d.item.origen.name}", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                      ),

                      // Input Cantidad
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: '0',
                          ),
                        ),
                      ),

                      // Botón "Todo"
                      IconButton(
                        icon: const Icon(Icons.all_inclusive, color: AppColors.primary),
                        tooltip: 'Entregar Todo',
                        onPressed: () => controller?.text = pendiente.toString(),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFirmas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Firmas Requeridas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildPadFirma("1. Autoriza Salida (S&G)", _firmaAutorizaCtrl),
          const SizedBox(height: 16),
          _buildPadFirma("2. Recibe Conforme (Cliente/Flete)", _firmaRecibeCtrl),
        ],
      ),
    );
  }

  Widget _buildPadFirma(String titulo, SignatureController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Signature(
                controller: ctrl,
                height: 120,
                backgroundColor: Colors.white,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                  onPressed: () => ctrl.clear(),
                  tooltip: 'Borrar firma',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _procesarDespacho() async {
    // 1. Recolectar datos
    final itemsAEnviar = <Map<String, dynamic>>[];
    bool hayItems = false;

    _controllers.forEach((id, ctrl) {
      final val = double.tryParse(ctrl.text) ?? 0;
      if (val > 0) {
        itemsAEnviar.add({'itemId': id, 'cantidad': val});
        hayItems = true;
      }
    });

    // 2. Validaciones
    if (!hayItems) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Ingresa al menos una cantidad a despachar")));
      return;
    }

    if (_firmaAutorizaCtrl.isEmpty || _firmaRecibeCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Ambas firmas son obligatorias")));
      return;
    }

    // 3. Enviar
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>().usuario;
      if (auth == null) throw Exception("Usuario no autenticado");

      final firmaAutorizaBytes = await _firmaAutorizaCtrl.toPngBytes();
      final firmaRecibeBytes = await _firmaRecibeCtrl.toPngBytes();

      if (firmaAutorizaBytes == null || firmaRecibeBytes == null) throw Exception("Error al procesar imágenes de firma");

      final exito = await context.read<OrdenInternaProvider>().generarRemito(
        ordenId: widget.ordenDetalle.orden.id!,
        items: itemsAEnviar,
        firmaAutoriza: firmaAutorizaBytes,
        firmaRecibe: firmaRecibeBytes,
        usuarioId: auth.uid,
        usuarioNombre: auth.nombre,
      );

      if (exito && mounted) {
        Navigator.pop(context, true); // Volver con éxito
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Remito generado y stock descontado"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            )
        );
      } else {
        if (mounted) {
          final errorMsg = context.read<OrdenInternaProvider>().errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${errorMsg ?? 'Desconocido'}"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}