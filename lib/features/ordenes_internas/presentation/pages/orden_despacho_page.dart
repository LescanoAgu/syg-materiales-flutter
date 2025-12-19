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
  final SignatureController _firmaAutorizaCtrl = SignatureController(
      penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  final SignatureController _firmaRecibeCtrl = SignatureController(
      penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);

  bool _isSubmitting = false;
  final Map<String, double> _cantidadesEntrega = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.ordenDetalle.items) {
      if (!item.estaCompleto) {
        _cantidadesEntrega[item.productoCodigo ?? item.materialId] = item.saldoPendiente.toDouble();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Entrega"), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Items a entregar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.ordenDetalle.items.length,
              itemBuilder: (ctx, i) {
                final item = widget.ordenDetalle.items[i];
                double pendiente = item.saldoPendiente.toDouble();
                if (pendiente <= 0) return const SizedBox.shrink();

                final key = item.productoCodigo ?? item.materialId;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.nombreMaterial, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Pendiente: $pendiente ${item.unidadBase}"),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: pendiente.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Cant", border: OutlineInputBorder()),
                            onChanged: (val) {
                              double valor = double.tryParse(val) ?? 0;
                              // Validación simple
                              if (valor > pendiente) valor = pendiente;
                              _cantidadesEntrega[key] = valor;
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            // Info de contexto para saber de dónde sale la mercadería
            if (widget.ordenDetalle.orden.proveedorId != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.orange[100],
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Atención: Esta entrega es del proveedor ${widget.ordenDetalle.orden.proveedorNombre}. NO descontará stock físico.")),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            const Text("Firmas de Conformidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            const Text("Autoriza Salida:"),
            Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: Signature(controller: _firmaAutorizaCtrl, height: 120, backgroundColor: Colors.white)
            ),

            const SizedBox(height: 12),
            const Text("Recibe Conforme:"),
            Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: Signature(controller: _firmaRecibeCtrl, height: 120, backgroundColor: Colors.white)
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmarDespacho,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMAR DESPACHO"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarDespacho() async {
    if (_firmaAutorizaCtrl.isEmpty || _firmaRecibeCtrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ambas firmas son obligatorias")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>().usuario;
      if (auth == null) throw Exception("Usuario no autenticado");

      List<Map<String, dynamic>> itemsAEnviar = [];
      _cantidadesEntrega.forEach((prodId, cant) {
        if (cant > 0) {
          final item = widget.ordenDetalle.items.firstWhere(
                  (i) => (i.productoCodigo == prodId) || (i.materialId == prodId),
              orElse: () => widget.ordenDetalle.items.first
          );

          itemsAEnviar.add({
            'productoId': prodId,
            'productoNombre': item.nombreMaterial,
            'cantidad': cant,
          });
        }
      });

      if (itemsAEnviar.isEmpty) throw Exception("No hay items para entregar");

      final firmaAutorizaBytes = await _firmaAutorizaCtrl.toPngBytes();
      final firmaRecibeBytes = await _firmaRecibeCtrl.toPngBytes();

      // Determinamos si es despacho de proveedor o propio basado en la orden
      // Si el tipo es 'proveedor', mandamos el ID para evitar descuento de stock
      String? proveedorIdParaRemito;
      String? proveedorNombreParaRemito;

      if (widget.ordenDetalle.orden.tipoDespacho == TipoDespacho.proveedor) {
        proveedorIdParaRemito = widget.ordenDetalle.orden.proveedorId ?? 'PR-GENERICO';
        proveedorNombreParaRemito = widget.ordenDetalle.orden.proveedorNombre ?? 'Proveedor Externo';
      }

      final exito = await context.read<OrdenInternaProvider>().generarRemito(
        ordenDetalle: widget.ordenDetalle,
        itemsAEntregar: itemsAEnviar,
        firmaAutoriza: firmaAutorizaBytes!,
        firmaRecibe: firmaRecibeBytes!,
        usuarioId: auth.uid,
        usuarioNombre: auth.nombre,
        proveedorId: proveedorIdParaRemito,
        proveedorNombre: proveedorNombreParaRemito,
      );

      if (exito && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Remito generado"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}