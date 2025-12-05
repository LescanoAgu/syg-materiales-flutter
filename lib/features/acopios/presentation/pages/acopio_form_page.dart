import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';

class AcopioFormPage extends StatefulWidget {
  const AcopioFormPage({super.key});

  @override
  State<AcopioFormPage> createState() => _AcopioFormPageState();
}

class _AcopioFormPageState extends State<AcopioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _facturaCtrl = TextEditingController();
  final _etiquetaCtrl = TextEditingController(); // Referencia (Obra)

  ClienteModel? _clienteSel;
  ProveedorModel? _proveedorSel;
  DateTime _fechaCompra = DateTime.now();

  // Lista de items a agregar
  final List<AcopioItem> _items = [];
  ProductoModel? _prodTemp;
  final _cantTempCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ProductoProvider>().cargarProductos();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Compra (Acopio)')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Datos de Cabecera
              const Text("Datos de la Factura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              CustomTextField(
                label: "N° Factura",
                controller: _facturaCtrl,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: "Etiqueta / Referencia (Ej: Obra Loyola)",
                controller: _etiquetaCtrl,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),

              // Selectores
              Consumer<ClienteProvider>(builder: (_, p, __) => DropdownButtonFormField<ClienteModel>(
                decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                items: p.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
                onChanged: (v) => setState(() => _clienteSel = v),
                validator: (v) => v == null ? 'Requerido' : null,
              )),
              const SizedBox(height: 10),
              Consumer<AcopioProvider>(builder: (_, p, __) => DropdownButtonFormField<ProveedorModel>(
                decoration: const InputDecoration(labelText: 'Proveedor', border: OutlineInputBorder()),
                items: p.proveedores.map((pr) => DropdownMenuItem(value: pr, child: Text(pr.nombre))).toList(),
                onChanged: (v) => setState(() => _proveedorSel = v),
                validator: (v) => v == null ? 'Requerido' : null,
              )),

              const Divider(height: 40),

              // 2. Agregar Productos
              const Text("Materiales Comprados", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Consumer<ProductoProvider>(builder: (_, p, __) => DropdownButtonFormField<ProductoModel>(
                      value: _prodTemp,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
                      items: p.productos.map((prod) => DropdownMenuItem(value: prod, child: Text(prod.nombre, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _prodTemp = v),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cantTempCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cant.', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 40, color: AppColors.primary),
                    onPressed: _agregarItem,
                  )
                ],
              ),

              // 3. Lista temporal
              const SizedBox(height: 20),
              if (_items.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Agrega productos a la lista", style: TextStyle(color: Colors.grey))))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_,__) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    return ListTile(
                      dense: true,
                      title: Text(item.productoNombre),
                      trailing: Text(item.cantidadOriginal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                      leading: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _items.isEmpty ? null : _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text("REGISTRAR FACTURA"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _agregarItem() {
    if (_prodTemp == null || _cantTempCtrl.text.isEmpty) return;
    final cant = double.tryParse(_cantTempCtrl.text) ?? 0;
    if (cant <= 0) return;

    setState(() {
      _items.add(AcopioItem(
        productoId: _prodTemp!.codigo,
        productoNombre: _prodTemp!.nombre,
        cantidadOriginal: cant,
        cantidadRestante: cant, // Al inicio, restante = original
      ));
      _prodTemp = null;
      _cantTempCtrl.clear();
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final acopio = AcopioModel(
      id: '', // Se genera en firebase
      numeroFactura: _facturaCtrl.text,
      etiqueta: _etiquetaCtrl.text,
      clienteId: _clienteSel!.id.isNotEmpty ? _clienteSel!.id : _clienteSel!.codigo,
      clienteRazonSocial: _clienteSel!.razonSocial,
      proveedorId: _proveedorSel!.id ?? _proveedorSel!.codigo,
      proveedorNombre: _proveedorSel!.nombre,
      fechaCompra: _fechaCompra,
      items: _items,
    );

    final exito = await context.read<AcopioProvider>().registrarIngreso(acopio);

    if (exito && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Factura registrada con éxito")));
    }
  }
}