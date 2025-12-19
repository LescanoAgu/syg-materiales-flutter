import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/producto_search_delegate.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../clientes/data/models/cliente_model.dart';

class AcopioFormPage extends StatefulWidget {
  const AcopioFormPage({super.key});

  @override
  State<AcopioFormPage> createState() => _AcopioFormPageState();
}

class _AcopioFormPageState extends State<AcopioFormPage> {
  final _nroFacturaCtrl = TextEditingController();
  DateTime _fechaCompra = DateTime.now();

  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;

  final List<AcopioItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  void _agregarProducto() async {
    final producto = await showSearch(
      context: context,
      delegate: ProductoSearchDelegate(),
    );

    if (producto != null && mounted) {
      _mostrarDialogoCantidad(producto);
    }
  }

  void _mostrarDialogoCantidad(ProductoModel producto) {
    final cantidadCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Agregar ${producto.nombre}"),
        content: TextField(
          controller: cantidadCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Cantidad (${producto.unidadBase})",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final cant = double.tryParse(cantidadCtrl.text) ?? 0;
              if (cant > 0) {
                setState(() {
                  final index = _items.indexWhere((i) => i.productoId == producto.id);
                  if (index != -1) {
                    // Sumamos si ya existe
                    _items[index] = _items[index].copyWith(
                      cantidadDisponible: _items[index].cantidadDisponible + cant,
                    );
                  } else {
                    // Agregamos nuevo
                    _items.add(AcopioItem(
                      productoId: producto.id ?? producto.codigo,
                      nombreProducto: producto.nombre,
                      cantidadTotalComprada: cant, // Inicialmente igual
                      cantidadDisponible: cant,
                      unidad: producto.unidadBase,
                    ));
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void _guardarAcopio() async {
    if (_clienteSeleccionado == null || _proveedorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos (Cliente o Proveedor)")));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agregá al menos un material")));
      return;
    }

    final nuevoAcopio = AcopioModel(
      id: null,
      clienteId: _clienteSeleccionado!.codigo,
      clienteRazonSocial: _clienteSeleccionado!.razonSocial,
      proveedorId: _proveedorSeleccionado!.id ?? '',
      proveedorNombre: _proveedorSeleccionado!.nombre,
      items: _items,
      fechaUltimoMovimiento: _fechaCompra,
    );

    final exito = await context.read<AcopioProvider>().registrarIngreso(nuevoAcopio);

    if (exito && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingreso registrado"), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingreso a Billetera"), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selectores
            Consumer<ClienteProvider>(
              builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
                value: _clienteSeleccionado,
                decoration: const InputDecoration(labelText: "Cliente Destino", border: OutlineInputBorder()),
                items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
                onChanged: (val) => setState(() => _clienteSeleccionado = val),
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AcopioProvider>(
              builder: (ctx, prov, _) => DropdownButtonFormField<ProveedorModel>(
                value: _proveedorSeleccionado,
                decoration: const InputDecoration(labelText: "Proveedor Origen", border: OutlineInputBorder()),
                items: prov.proveedores.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
                onChanged: (val) => setState(() => _proveedorSeleccionado = val),
              ),
            ),
            const SizedBox(height: 12),
            // Factura y Fecha
            Row(
              children: [
                Expanded(child: CustomTextField(label: "N° Factura (Ref)", controller: _nroFacturaCtrl)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _fechaCompra, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setState(() => _fechaCompra = d);
                  },
                ),
                Text(DateFormat('dd/MM/yyyy').format(_fechaCompra)),
              ],
            ),

            const Divider(height: 32),

            // Lista Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Materiales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _agregarProducto,
                  icon: const Icon(Icons.add),
                  label: const Text("Agregar"),
                )
              ],
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_,__) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return ListTile(
                  title: Text(item.nombreProducto),
                  subtitle: Text("Saldo: ${item.cantidadDisponible} ${item.unidad}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _items.removeAt(i)),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardarAcopio,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text("CONFIRMAR INGRESO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}