// lib/features/ordenes_internas/presentation/pages/orden_form_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../providers/orden_interna_provider.dart';

/// Formulario para crear una nueva Orden Interna
class OrdenFormPage extends StatefulWidget {
  const OrdenFormPage({super.key});

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _observacionesController = TextEditingController();

  // Estado
  int? _clienteSeleccionadoId;
  int? _obraSeleccionadaId;  // ⭐ YA NO ES OPCIONAL
  DateTime _fechaSolicitud = DateTime.now();
  String _prioridad = 'normal';

  @override
  void initState() {
    super.initState();
    // Cargar clientes y obras al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ObraProvider>().cargarObras();
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ========================================
    // 🔥 ARREGLO 1: PopScope para manejar botón volver
    // ========================================
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          print('👈 Usuario volvió desde orden form');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nueva Orden Interna'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildSelectorCliente(),
                const SizedBox(height: 16),
                _buildSelectorObra(),
                const SizedBox(height: 16),
                _buildSelectorFecha(),
                const SizedBox(height: 16),
                _buildSelectorPrioridad(),
                const SizedBox(height: 16),
                _buildCampoObservaciones(),
                const SizedBox(height: 24),
                _buildBotonCrear(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // INFORMACIÓN
  // ========================================
  Widget _buildInfoCard() {
    return Card(
      color: AppColors.info.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completa el formulario para crear una nueva orden interna. Todos los campos son obligatorios.',
                style: TextStyle(color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // SELECTOR DE CLIENTE
  // ========================================
  Widget _buildSelectorCliente() {
    return Card(
      child: Consumer<ClienteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Cargando clientes...'),
            );
          }

          final clienteSeleccionado = provider.clientes
              .where((c) => c.id == _clienteSeleccionadoId)
              .firstOrNull;

          return ListTile(
            leading: const Icon(Icons.business, color: AppColors.primary),
            title: Text(
              clienteSeleccionado?.razonSocial ?? 'Seleccionar cliente',
              style: TextStyle(
                fontWeight: clienteSeleccionado != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: clienteSeleccionado != null
                ? Text('Código: ${clienteSeleccionado.codigo}')
                : const Text('Requerido'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _mostrarSelectorClientes(),
          );
        },
      ),
    );
  }

  // ========================================
  // SELECTOR DE OBRA
  // ========================================
  Widget _buildSelectorObra() {
    return Card(
      // ⭐ ARREGLO 3: Obra obligatoria - fondo rojo si no está seleccionada
      color: _obraSeleccionadaId == null
          ? AppColors.error.withOpacity(0.05)
          : null,
      child: Consumer<ObraProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Cargando obras...'),
            );
          }

          // Filtrar obras del cliente seleccionado
          final obrasDelCliente = _clienteSeleccionadoId != null
              ? provider.obras.where((o) => o.obra.clienteId == _clienteSeleccionadoId).toList()
              : provider.obras;

          final obraSeleccionada = obrasDelCliente
              .where((o) => o.obra.id == _obraSeleccionadaId)
              .firstOrNull;

          return ListTile(
            leading: Icon(
              Icons.location_city,
              color: _obraSeleccionadaId != null
                  ? AppColors.primary
                  : AppColors.error,
            ),
            title: Text(
              obraSeleccionada?.obra.nombre ?? 'Seleccionar obra',
              style: TextStyle(
                fontWeight: obraSeleccionada != null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _obraSeleccionadaId == null
                    ? AppColors.error
                    : AppColors.textDark,
              ),
            ),
            subtitle: obraSeleccionada != null
                ? Text('Código: ${obraSeleccionada.obra.codigo}')
                : const Text('⚠️ OBLIGATORIO - Selecciona una obra'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (_clienteSeleccionadoId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Primero selecciona un cliente'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              _mostrarSelectorObras(obrasDelCliente);
            },
          );
        },
      ),
    );
  }

  // ========================================
  // SELECTOR DE FECHA
  // ========================================
  Widget _buildSelectorFecha() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
        title: const Text('Fecha de Solicitud'),
        subtitle: Text(
          DateFormat('dd/MM/yyyy').format(_fechaSolicitud),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para limpiar fecha (volver a hoy)
            if (_fechaSolicitud.day != DateTime.now().day ||
                _fechaSolicitud.month != DateTime.now().month ||
                _fechaSolicitud.year != DateTime.now().year)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  setState(() {
                    _fechaSolicitud = DateTime.now();
                  });
                },
                tooltip: 'Volver a hoy',
              ),
            const Icon(Icons.edit, size: 16),
          ],
        ),
        onTap: () async {
          // ========================================
          // 🔥 ARREGLO 2: Selector de fecha corregido
          // ========================================
          final fechaSeleccionada = await showDatePicker(
            context: context,
            initialDate: _fechaSolicitud,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            locale: const Locale('es', 'AR'),
            helpText: 'Seleccionar fecha',
            cancelText: 'Cancelar',
            confirmText: 'Aceptar',
            // Configuración regional para Argentina
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (fechaSeleccionada != null && mounted) {
            setState(() {
              _fechaSolicitud = fechaSeleccionada;
            });
          }
        },
      ),
    );
  }

  // ========================================
  // SELECTOR DE PRIORIDAD
  // ========================================
  Widget _buildSelectorPrioridad() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prioridad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPrioridadChip('baja', 'Baja', AppColors.info),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPrioridadChip('normal', 'Normal', AppColors.success),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPrioridadChip('alta', 'Alta', AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPrioridadChip('urgente', 'Urgente', AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioridadChip(String valor, String etiqueta, Color color) {
    final isSelected = _prioridad == valor;

    return InkWell(
      onTap: () => setState(() => _prioridad = valor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          etiqueta,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ========================================
  // CAMPO OBSERVACIONES
  // ========================================
  Widget _buildCampoObservaciones() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _observacionesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observaciones (Opcional)',
            hintText: 'Escribe cualquier observación o nota adicional...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ========================================
  // BOTÓN CREAR
  // ========================================
  Widget _buildBotonCrear() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _validarYCrearOrden,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Crear Orden Interna',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ========================================
  // LÓGICA
  // ========================================

  Future<void> _mostrarSelectorClientes() async {
    final clientes = context.read<ClienteProvider>().clientes;

    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clientes disponibles'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final clienteSeleccionado = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Cliente'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final cliente = clientes[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.business),
                  ),
                  title: Text(cliente.razonSocial),
                  subtitle: Text(cliente.codigo),
                  onTap: () => Navigator.pop(context, cliente.id),
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
        );
      },
    );

    if (clienteSeleccionado != null && mounted) {
      setState(() {
        _clienteSeleccionadoId = clienteSeleccionado;
        _obraSeleccionadaId = null; // Resetear obra al cambiar cliente
      });

      // Cargar obras del cliente
      context.read<ObraProvider>().cargarObras();
    }
  }

  Future<void> _mostrarSelectorObras(List<dynamic> obrasDelCliente) async {
    if (obrasDelCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene obras disponibles'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final obraSeleccionada = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Obra'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: obrasDelCliente.length,
              itemBuilder: (context, index) {
                final obraData = obrasDelCliente[index];
                final obra = obraData.obra;
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.location_city),
                  ),
                  title: Text(obra.nombre),
                  subtitle: Text('${obra.codigo} - ${obra.direccion}'),
                  onTap: () => Navigator.pop(context, obra.id),
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
        );
      },
    );

    if (obraSeleccionada != null && mounted) {
      setState(() {
        _obraSeleccionadaId = obraSeleccionada;
      });
    }
  }

  Future<void> _validarYCrearOrden() async {
    // ========================================
    // VALIDACIONES OBLIGATORIAS
    // ========================================

    // Validar cliente
    if (_clienteSeleccionadoId == null) {
      _mostrarError('⚠️ Debes seleccionar un cliente');
      return;
    }

    // ⭐ ARREGLO 3: Validar que la obra sea obligatoria
    if (_obraSeleccionadaId == null) {
      _mostrarError('⚠️ Debes seleccionar una obra (campo obligatorio)');
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Mostrar confirmación
    final confirmado = await _mostrarDialogoConfirmacion();
    if (!confirmado) return;

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Crear orden
    try {
      // ========================================
      // 🔥 CORRECCIÓN: Usar los parámetros correctos del provider
      // ========================================
      final exito = await context.read<OrdenInternaProvider>().crearOrden(
        clienteId: _clienteSeleccionadoId!,
        obraId: _obraSeleccionadaId!,
        solicitanteNombre: 'Usuario Sistema', // TODO: Obtener del usuario logueado
        items: [], // Lista vacía inicial, se pueden agregar después
        fechaSolicitud: _fechaSolicitud, // ✅ Ahora sí funciona
        prioridad: _prioridad,           // ✅ Ahora sí funciona
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(), // ✅ Ahora sí funciona
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      if (exito) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Orden Interna creada correctamente'),
              backgroundColor: AppColors.success,
            ),
          );

          // Volver a la pantalla anterior
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          _mostrarError('Error al crear la orden interna');
        }
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.pop(context);
      if (mounted) {
        _mostrarError('Error: ${e.toString()}');
      }
    }
  }

  Future<bool> _mostrarDialogoConfirmacion() async {
    final cliente = context.read<ClienteProvider>().clientes
        .firstWhere((c) => c.id == _clienteSeleccionadoId);

    final obra = context.read<ObraProvider>().obras
        .firstWhere((o) => o.obra.id == _obraSeleccionadaId);

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Orden Interna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Deseas crear esta orden interna?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Cliente:', cliente.razonSocial),
              _buildInfoRow('Obra:', obra.obra.nombre),
              _buildInfoRow(
                'Fecha:',
                DateFormat('dd/MM/yyyy').format(_fechaSolicitud),
              ),
              _buildInfoRow('Prioridad:', _prioridad.toUpperCase()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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