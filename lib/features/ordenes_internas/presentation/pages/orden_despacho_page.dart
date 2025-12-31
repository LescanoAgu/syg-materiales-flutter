import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../acopios/data/models/acopio_model.dart';

class OrdenDespachoPage extends StatefulWidget {
  final OrdenInternaDetalle ordenDetalle;

  const OrdenDespachoPage({super.key, required this.ordenDetalle});

  @override
  State<OrdenDespachoPage> createState() => _OrdenDespachoPageState();
}

class _OrdenDespachoPageState extends State<OrdenDespachoPage> {
  final SignatureController _firmaAutorizaCtrl = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);
  final SignatureController _firmaRecibeCtrl = SignatureController(penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);

  bool _isSubmitting = false;
  bool _isLoadingStock = true;

  // Mapas para control
  final Map<String, double> _cantidadesEntrega = {}; // Lo que el usuario escribe
  final Map<String, double> _limitesStock = {};      // El stock real disponible (Físico o Acopio)
  final Map<String, String> _erroresStock = {};      // Mensajes de error por item

  @override
  void initState() {
    super.initState();
    _verificarDisponibilidad();
  }

  // --- LÓGICA DE VALIDACIÓN DE STOCK ---
  Future<void> _verificarDisponibilidad() async {
    final orden = widget.ordenDetalle.orden;
    final db = FirebaseFirestore.instance;

    try {
      for (var item in widget.ordenDetalle.items) {
        if (item.estaCompleto) continue;

        double stockDisponible = 0.0;

        // CASO A: RETIRO DE ACOPIO
        if (orden.origen == OrigenAbastecimiento.acopio_cliente && orden.acopioId != null) {
          final doc = await db.collection('acopios').doc(orden.acopioId).get();
          if (doc.exists) {
            final acopio = AcopioModel.fromSnapshot(doc);
            // Buscamos el item en la billetera
            final itemAcopio = acopio.items.firstWhere(
                    (i) => i.productoId == item.materialId,
                // ✅ CORREGIDO: Usamos nombreProducto y cantidadDisponible
                orElse: () => const AcopioItem(productoId: '', nombreProducto: '', cantidadTotalComprada: 0, cantidadDisponible: 0)
            );
            stockDisponible = itemAcopio.cantidadDisponible;
          }
        }
        // CASO B: STOCK PROPIO
        else if (orden.origen == OrigenAbastecimiento.stock_propio) {
          final doc = await db.collection('productos').doc(item.materialId).get();
          if (doc.exists) {
            stockDisponible = (doc.data()?['cantidadDisponible'] as num?)?.toDouble() ?? 0.0;
          }
        }
        // CASO C: COMPRA PROVEEDOR
        else {
          stockDisponible = 999999.0;
        }

        if (mounted) {
          setState(() {
            _limitesStock[item.materialId] = stockDisponible;
            _cantidadesEntrega[item.materialId] = 0.0;
          });
        }
      }
    } catch (e) {
      print("Error verificando stock: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStock = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Entrega"), backgroundColor: AppColors.primary),
      body: _isLoadingStock
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Verificando Stock...")]))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue)),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Origen: ${widget.ordenDetalle.orden.origen.name.toUpperCase()}\nProveedor: ${widget.ordenDetalle.orden.proveedorNombre ?? 'S&G'}")),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("Items a entregar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.ordenDetalle.items.length,
              separatorBuilder: (_,__) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = widget.ordenDetalle.items[i];
                double solicitado = item.cantidad.toDouble();
                double entregadoPrev = item.cantidadEntregada.toDouble();
                double pendienteDeEntrega = solicitado - entregadoPrev;

                if (pendienteDeEntrega <= 0) return const SizedBox.shrink();

                double stockReal = _limitesStock[item.materialId] ?? 0.0;
                bool sinStock = stockReal <= 0;

                return Card(
                  color: sinStock ? Colors.red[50] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.nombreMaterial, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("Pedido: ${item.cantidad} | Entregado: ${item.cantidadEntregada}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text("Falta entregar: $pendienteDeEntrega", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  Text("Stock Disponible: $stockReal", style: TextStyle(fontWeight: FontWeight.bold, color: sinStock ? Colors.red : Colors.green)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: '0',
                                keyboardType: TextInputType.number,
                                enabled: !sinStock,
                                decoration: InputDecoration(
                                  labelText: "Cant",
                                  border: const OutlineInputBorder(),
                                  errorText: _erroresStock[item.materialId],
                                ),
                                onChanged: (val) {
                                  double valorIngresado = double.tryParse(val) ?? 0;

                                  setState(() {
                                    if (valorIngresado > pendienteDeEntrega) {
                                      _erroresStock[item.materialId] = "Máx: $pendienteDeEntrega";
                                      _cantidadesEntrega[item.materialId] = 0;
                                    } else if (valorIngresado > stockReal) {
                                      _erroresStock[item.materialId] = "Stock: $stockReal";
                                      _cantidadesEntrega[item.materialId] = 0;
                                    } else {
                                      _erroresStock.remove(item.materialId);
                                      _cantidadesEntrega[item.materialId] = valorIngresado;
                                    }
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                        if (sinStock)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text("⚠️ SIN STOCK", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text("Firmas de Conformidad", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            const Text("Autoriza Salida:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: Signature(controller: _firmaAutorizaCtrl, height: 100, backgroundColor: Colors.white)),

            const SizedBox(height: 12),
            const Text("Recibe Conforme:"),
            Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey)), child: Signature(controller: _firmaRecibeCtrl, height: 100, backgroundColor: Colors.white)),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmarDespacho,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRMAR Y GENERAR REMITO"),
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

    if (_erroresStock.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Corrige las cantidades en rojo antes de seguir")));
      return;
    }

    final itemsAEnviar = <Map<String, dynamic>>[];
    _cantidadesEntrega.forEach((key, val) {
      if (val > 0) {
        itemsAEnviar.add({
          'productoId': key,
          'cantidad': val,
        });
      }
    });

    if (itemsAEnviar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes ingresar al menos una cantidad válida")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>().usuario;
      final firmaAuthBytes = await _firmaAutorizaCtrl.toPngBytes();
      final firmaRecibeBytes = await _firmaRecibeCtrl.toPngBytes();

      final exito = await context.read<OrdenInternaProvider>().generarRemito(
          ordenDetalle: widget.ordenDetalle,
          itemsAEntregar: itemsAEnviar,
          firmaAutoriza: firmaAuthBytes!,
          firmaRecibe: firmaRecibeBytes!,
          usuarioId: auth?.uid ?? 'sys',
          usuarioNombre: auth?.nombre ?? 'Sistema',
          proveedorId: widget.ordenDetalle.orden.proveedorId,
          proveedorNombre: widget.ordenDetalle.orden.proveedorNombre
      );

      if (exito && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Remito generado correctamente"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }
}