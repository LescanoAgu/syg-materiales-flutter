import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../../../core/constants/app_colors.dart';
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

  final SignatureController _firmaAutorizaCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white
  );
  final SignatureController _firmaRecibeCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white
  );

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(title: const Text('Generar Remito de Entrega')),
      body: _isSubmitting
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Generando Remito y Firmas...")]))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBigHeader(), // ✅ HEADER GIGANTE NUEVO

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seleccionar Materiales a Entregar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  _buildListaItems(),
                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  const Text("Firmas Requeridas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  _buildSeccionFirmas(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 28),
                      label: const Text("CONFIRMAR Y GENERAR REMITO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          elevation: 5
                      ),
                      onPressed: _procesarDespacho,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CLIENTE", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(
            widget.ordenDetalle.clienteRazonSocial.toUpperCase(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          const Text("OBRA / DESTINO", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(
            widget.ordenDetalle.obraNombre?.toUpperCase() ?? "SIN OBRA",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("RESPONSABLE", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(widget.ordenDetalle.orden.solicitanteNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  children: [
                    const Text("ORDEN INTERNA", style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Text(widget.ordenDetalle.orden.numero, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildListaItems() {
    final pendientes = widget.ordenDetalle.items.where((i) => !i.estaCompleto).toList();

    if (pendientes.isEmpty) return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: Text("¡Todo entregado! No hay items pendientes.")),
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendientes.length,
      separatorBuilder: (_,__) => const Divider(),
      itemBuilder: (ctx, i) {
        final d = pendientes[i];
        final pendiente = d.cantidadFinal - d.item.cantidadEntregada;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.productoNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: Text(d.item.origen.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text("Faltan: ${pendiente.toStringAsFixed(1)} ${d.unidadBase}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _controllers[d.item.id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                      labelText: 'Cant.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.all_inclusive, color: AppColors.primary),
                tooltip: 'Entregar Todo',
                onPressed: () => _controllers[d.item.id]!.text = pendiente.toString(),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccionFirmas() {
    return Column(
      children: [
        _buildPadFirma("1. Autoriza Salida (Pañol/S&G)", _firmaAutorizaCtrl),
        const SizedBox(height: 20),
        _buildPadFirma("2. Recibe Conforme (Cliente/Flete)", _firmaRecibeCtrl),
      ],
    );
  }

  Widget _buildPadFirma(String titulo, SignatureController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
          ),
          child: Stack(
            children: [
              Signature(
                controller: ctrl,
                height: 160,
                backgroundColor: Colors.white,
              ),
              Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => ctrl.clear(),
                  tooltip: 'Borrar firma',
                ),
              ),
              const Positioned(
                bottom: 5,
                left: 5,
                child: Text("Firme dentro del recuadro", style: TextStyle(color: Colors.grey, fontSize: 10)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _procesarDespacho() async {
    // 1. Validar cantidades
    final itemsAEnviar = <Map<String, dynamic>>[];
    bool hayItems = false;

    _controllers.forEach((id, ctrl) {
      final val = double.tryParse(ctrl.text) ?? 0;
      if (val > 0) {
        itemsAEnviar.add({'itemId': id, 'cantidad': val});
        hayItems = true;
      }
    });

    if (!hayItems) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Ingresa al menos una cantidad a despachar")));
      return;
    }

    // 2. Validar Firmas
    if (_firmaAutorizaCtrl.isEmpty || _firmaRecibeCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Ambas firmas son obligatorias para el remito")));
      return;
    }

    // 3. Procesar
    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>().usuario;
      if (auth == null) throw Exception("Usuario no autenticado");

      final firmaAutorizaBytes = await _firmaAutorizaCtrl.toPngBytes();
      final firmaRecibeBytes = await _firmaRecibeCtrl.toPngBytes();

      if (firmaAutorizaBytes == null || firmaRecibeBytes == null) throw Exception("Error procesando firmas");

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
              content: Text("✅ Remito generado y guardado correctamente"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            )
        );
      } else {
        if (mounted) {
          final errorMsg = context.read<OrdenInternaProvider>().errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${errorMsg ?? 'Desconocido'}"), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Excepción UI: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}