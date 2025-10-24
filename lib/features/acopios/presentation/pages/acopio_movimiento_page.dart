// ========================================
// ARCHIVO CORREGIDO: lib/features/acopios/presentation/pages/acopio_movimiento_page.dart
// ✅ FIX: Agregado WillPopScope y leading button
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/data/models/stock_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/acopio_provider.dart';

class AcopioMovimientoPage extends StatefulWidget {
  final AcopioDetalle? acopioInicial;

  const AcopioMovimientoPage({
    super.key,
    this.acopioInicial,
  });

  @override
  State<AcopioMovimientoPage> createState() => _AcopioMovimientoPageState();
}

class _AcopioMovimientoPageState extends State<AcopioMovimientoPage> {
  // ========================================
  // ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _facturaNumeroController = TextEditingController();

  TipoMovimientoAcopio _tipoMovimiento = TipoMovimientoAcopio.entrada;
  ProductoConStock? _productoSeleccionado;
  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;
  bool _valorizar = false;
  DateTime? _facturaFecha;

  @override
  void initState() {
    super.initState();

    if (widget.acopioInicial != null) {
      _tipoMovimiento = TipoMovimientoAcopio.salida;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
    _facturaNumeroController.dispose();
    super.dispose();
  }

  // ========================================
  // BUILD - ✅ CON WILLPOPSCOPE
  // ========================================

  @override
  Widget build(BuildContext context) {
    // 👉 CAMBIO 1: Envolver con WillPopScope
    return WillPopScope(
      onWillPop: () async {
        // Permitir salir siempre (sin confirmación)
        return true;
      },
      child: Scaffold(
        // ========================================
        // APP BAR - ✅ CON LEADING BUTTON
        // ========================================
        appBar: AppBar(
          // 👉 CAMBIO 2: Agregar leading button explícito
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
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
          title: const Text('Registrar Movimiento de Acopio'),
        ),

        // ========================================
        // BODY
        // ========================================
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de movimiento
                _buildSeccionTitulo('Tipo de Movimiento'),
                _buildSelectorTipo(),
                const SizedBox(height: 24),

                // Producto
                _buildSeccionTitulo('Producto'),
                _buildSelectorProducto(),
                const SizedBox(height: 24),

                // Cliente
                _buildSeccionTitulo('Cliente'),
                _buildSelectorCliente(),
                const SizedBox(height: 24),

                // Proveedor
                _buildSeccionTitulo('Ubicación (Proveedor)'),
                _buildSelectorProveedor(),
                const SizedBox(height: 24),

                // Cantidad
                _buildSeccionTitulo('Cantidad'),
                _buildCampoCantidad(),
                const SizedBox(height: 24),

                // Factura (opcional)
                _buildSeccionTitulo('Factura (Opcional)'),
                _buildCampoFactura(),
                const SizedBox(height: 24),

                // Motivo (opcional)
                _buildSeccionTitulo('Motivo (Opcional)'),
                _buildCampoMotivo(),
                const SizedBox(height: 32),

                // Botón registrar
                _buildBotonRegistrar(),
              ],
            ),
          ),
        ),
      ), // 👈 Cierra WillPopScope
    );
  }

  // ========================================
  // WIDGETS DE UI (sin cambios)
  // ========================================

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return SegmentedButton<TipoMovimientoAcopio>(
      segments: const [
        ButtonSegment(
          value: TipoMovimientoAcopio.entrada,
          label: Text('Entrada'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: TipoMovimientoAcopio.salida,
          label: Text('Salida'),
          icon: Icon(Icons.arrow_upward),
        ),
      ],
      selected: {_tipoMovimiento},
      onSelectionChanged: (Set<TipoMovimientoAcopio> newSelection) {
        setState(() {
          _tipoMovimiento = newSelection.first;
        });
      },
    );
  }

  Widget _buildSelectorProducto() {
    if (_productoSeleccionado != null) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.inventory_2, color: AppColors.primary),
          ),
          title: Text(_productoSeleccionado!.productoNombre),
          subtitle: Text(_productoSeleccionado!.productoCodigo),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Mostrar diálogo de productos
            },
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () {
        // Mostrar diálogo de productos
      },
      icon: const Icon(Icons.add),
      label: const Text('Seleccionar Producto'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person, color: AppColors.primary),
        title: Text(_clienteSeleccionado?.razonSocial ?? 'Seleccionar Cliente'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Mostrar diálogo de clientes
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
          // Mostrar diálogo de proveedores
        },
      ),
    );
  }

  Widget _buildCampoCantidad() {
    return TextFormField(
      controller: _cantidadController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Ej: 10',
        prefixIcon: const Icon(Icons.numbers),
        suffix: _productoSeleccionado != null
            ? Text(_productoSeleccionado!.unidadBase)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa una cantidad';
        }
        if (double.tryParse(value) == null) {
          return 'Ingresa un número válido';
        }
        if (double.parse(value) <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildCampoFactura() {
    return TextFormField(
      controller: _facturaNumeroController,
      decoration: InputDecoration(
        hintText: 'Ej: FC-0001-00012345',
        prefixIcon: const Icon(Icons.receipt),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCampoMotivo() {
    return TextFormField(
      controller: _motivoController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Ej: Compra para obra X',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _registrarMovimiento,
        icon: const Icon(Icons.check_circle),
        label: const Text(
          'REGISTRAR MOVIMIENTO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ========================================
  // LÓGICA DE REGISTRO
  // ========================================

  Future<void> _registrarMovimiento() async {
    if (_productoSeleccionado == null) {
      _mostrarError('Debes seleccionar un producto');
      return;
    }

    if (_clienteSeleccionado == null) {
      _mostrarError('Debes seleccionar un cliente');
      return;
    }

    if (_proveedorSeleccionado == null) {
      _mostrarError('Debes seleccionar un proveedor');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = double.parse(_cantidadController.text);

    final exito = await context.read<AcopioProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId,
      clienteId: _clienteSeleccionado!.id!,
      proveedorId: _proveedorSeleccionado!.id!,
      tipo: _tipoMovimiento,
      cantidad: cantidad,
      motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      facturaNumero: _facturaNumeroController.text.isEmpty ? null : _facturaNumeroController.text,
      facturaFecha: _facturaFecha,
      valorizado: _valorizar,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento registrado: ${_tipoMovimiento.name.toUpperCase()} de $cantidad ${_productoSeleccionado!.unidadBase}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, true);
    } else if (mounted) {
      _mostrarError('Error al registrar el movimiento');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
      ),
    );
  }
}