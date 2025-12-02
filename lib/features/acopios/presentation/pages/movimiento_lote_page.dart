import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_lote_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/acopio_provider.dart';

class MovimientoLotePage extends StatefulWidget {
  const MovimientoLotePage({super.key});

  @override
  State<MovimientoLotePage> createState() => _MovimientoLotePageState();
}

class _MovimientoLotePageState extends State<MovimientoLotePage> {
  final _formKey = GlobalKey<FormState>();
  final _facturaNumeroController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _remitoController = TextEditingController();

  TipoDestinoLote _tipoDestino = TipoDestinoLote.stock;
  bool _esEntrada = true;
  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;

  final List<MovimientoLoteItem> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  void dispose() {
    _facturaNumeroController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
    _remitoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_items.isNotEmpty) {
          final bool? confirmar = await _mostrarDialogoConfirmacion();
          if (confirmar == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_items.isNotEmpty) {
                final bool? confirmar = await _mostrarDialogoConfirmacion();
                if (confirmar == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Movimiento en Lote'),
              Text(
                '${_items.length} productos agregados',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSelectorTipoDestino(),
                      const SizedBox(height: 16),
                      _buildSelectorEntradaSalida(),
                      const SizedBox(height: 16),
                      if (_tipoDestino == TipoDestinoLote.acopio) ...[
                        _buildSelectorCliente(),
                        const SizedBox(height: 16),
                        _buildSelectorProveedor(),
                        const SizedBox(height: 16),
                      ],
                      _buildCamposOpcionales(),
                      const SizedBox(height: 16),
                      _buildListaProductos(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBotonesInferiores(),
          ],
        ),
      ),
    );
  }

  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin guardar?'),
        content: Text(
          'Tienes ${_items.length} producto${_items.length == 1 ? '' : 's'} agregado${_items.length == 1 ? '' : 's'}.\n\n'
          '¿Deseas salir sin registrar el movimiento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Salir sin guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTipoDestino() {
    return SegmentedButton<TipoDestinoLote>(
      segments: const [
        ButtonSegment(
          value: TipoDestinoLote.stock,
          label: Text('Stock S&G'),
          icon: Icon(Icons.warehouse),
        ),
        ButtonSegment(
          value: TipoDestinoLote.acopio,
          label: Text('Acopio Cliente'),
          icon: Icon(Icons.inventory),
        ),
      ],
      selected: {_tipoDestino},
      onSelectionChanged: (Set<TipoDestinoLote> newSelection) {
        setState(() {
          _tipoDestino = newSelection.first;
        });
      },
    );
  }

  Widget _buildSelectorEntradaSalida() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          label: Text('Entrada'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: false,
          label: Text('Salida'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {_esEntrada},
      onSelectionChanged: (Set<bool> newSelection) {
        setState(() {
          _esEntrada = newSelection.first;
        });
      },
    );
  }

  Widget _buildSelectorCliente() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person, color: AppColors.primary),
        title: Text(_clienteSeleccionado?.razonSocial ?? 'Seleccionar Cliente'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Lógica de selección de cliente
        },
      ),
    );
  }

  Widget _buildSelectorProveedor() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.store, color: AppColors.success),
        title: Text(_proveedorSeleccionado?.nombre ?? 'Seleccionar Proveedor'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Lógica de selección de proveedor
        },
      ),
    );
  }

  Widget _buildCamposOpcionales() {
    return Column(
      children: [
        TextFormField(
          controller: _facturaNumeroController,
          decoration: const InputDecoration(
            labelText: 'N° Factura (Opcional)',
            prefixIcon: Icon(Icons.receipt),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo (Opcional)',
            prefixIcon: Icon(Icons.description),
          ),
        ),
      ],
    );
  }

  Widget _buildListaProductos() {
    if (_items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay productos agregados',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos (${_items.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _items.length,
          (index) => _buildItemCard(_items[index], index),
        ),
      ],
    );
  }

  Widget _buildItemCard(MovimientoLoteItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.producto.productoNombre),
        subtitle: Text('${item.cantidad} ${item.producto.unidadBase}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: () {
            setState(() {
              _items.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  Widget _buildBotonesInferiores() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Lógica para agregar producto
              },
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty
                  ? null
                  : () async {
                      // Llamar a _registrarLote()
                    },
              icon: const Icon(Icons.check_circle),
              label: const Text('REGISTRAR TODO'),
            ),
          ),
        ],
      ),
    );
  }
}
