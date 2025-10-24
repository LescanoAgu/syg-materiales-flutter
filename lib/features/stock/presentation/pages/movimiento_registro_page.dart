// ========================================
// ARCHIVO CORREGIDO: lib/features/stock/presentation/pages/movimiento_registro_page.dart
// ✅ FIX: Agregado WillPopScope y leading button
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/stock_model.dart';
import '../providers/producto_provider.dart';
import '../providers/movimiento_stock_provider.dart';

/// Pantalla para REGISTRAR movimientos de stock
class MovimientoRegistroPage extends StatefulWidget {
  final ProductoConStock? productoInicial;

  const MovimientoRegistroPage({
    super.key,
    this.productoInicial,
  });

  @override
  State<MovimientoRegistroPage> createState() => _MovimientoRegistroPageState();
}

class _MovimientoRegistroPageState extends State<MovimientoRegistroPage> {
  // ========================================
  // CONTROLADORES Y ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();

  ProductoConStock? _productoSeleccionado;
  TipoMovimiento _tipoSeleccionado = TipoMovimiento.entrada;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;

    if (_productoSeleccionado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductoProvider>().cargarProductos();
      });
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
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
        // Permitir cerrar la pantalla
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
          title: const Text('Registrar Movimiento'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),

        // ========================================
        // BODY
        // ========================================
        body: Consumer<MovimientoStockProvider>(
          builder: (context, movProvider, child) {
            if (movProvider.isRegistering) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Registrando movimiento...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeccionTitulo('Producto'),
                    _buildSelectorProducto(),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Tipo de Movimiento'),
                    _buildSelectorTipo(),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Cantidad'),
                    _buildCampoCantidad(),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Motivo (Opcional)'),
                    _buildCampoMotivo(),
                    const SizedBox(height: 24),

                    _buildSeccionTitulo('Referencia (Opcional)'),
                    _buildCampoReferencia(),
                    const SizedBox(height: 32),

                    _buildBotonRegistrar(),
                  ],
                ),
              ),
            );
          },
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

  Widget _buildSelectorProducto() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        if (_productoSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.inventory_2, color: AppColors.primary),
              ),
              title: Text(_productoSeleccionado!.productoNombre),
              subtitle: Text(
                '${_productoSeleccionado!.productoCodigo} • Stock: ${_productoSeleccionado!.cantidadDisponible} ${_productoSeleccionado!.unidadBase}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _mostrarDialogoProductos(provider.productos),
              ),
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: () => _mostrarDialogoProductos(provider.productos),
          icon: const Icon(Icons.add),
          label: const Text('Seleccionar Producto'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        );
      },
    );
  }

  void _mostrarDialogoProductos(List<ProductoConStock> productos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Producto'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(producto.productoCodigo.substring(0, 2)),
                ),
                title: Text(producto.productoNombre),
                subtitle: Text('${producto.productoCodigo} • ${producto.categoriaNombre}'),
                trailing: Text('${producto.cantidadDisponible} ${producto.unidadBase}'),
                onTap: () {
                  setState(() {
                    _productoSeleccionado = producto;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return SegmentedButton<TipoMovimiento>(
      segments: const [
        ButtonSegment(
          value: TipoMovimiento.entrada,
          label: Text('Entrada'),
          icon: Icon(Icons.arrow_downward),
        ),
        ButtonSegment(
          value: TipoMovimiento.salida,
          label: Text('Salida'),
          icon: Icon(Icons.arrow_upward),
        ),
        ButtonSegment(
          value: TipoMovimiento.ajuste,
          label: Text('Ajuste'),
          icon: Icon(Icons.tune),
        ),
      ],
      selected: {_tipoSeleccionado},
      onSelectionChanged: (Set<TipoMovimiento> newSelection) {
        setState(() {
          _tipoSeleccionado = newSelection.first;
        });
      },
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

  Widget _buildCampoMotivo() {
    return TextFormField(
      controller: _motivoController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Ej: Compra a proveedor, Venta cliente X, etc.',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCampoReferencia() {
    return TextFormField(
      controller: _referenciaController,
      decoration: InputDecoration(
        hintText: 'Ej: OC-001, REM-1234, etc.',
        prefixIcon: const Icon(Icons.tag),
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = double.parse(_cantidadController.text);

    final exito = await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId,
      tipo: _tipoSeleccionado,
      cantidad: cantidad,
      motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      referencia: _referenciaController.text.isEmpty ? null : _referenciaController.text,
      usuarioId: null,
    );

    if (exito && mounted) {
      await context.read<ProductoProvider>().cargarProductos();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento registrado: ${_tipoSeleccionado.name.toUpperCase()} de $cantidad ${_productoSeleccionado!.unidadBase}',
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