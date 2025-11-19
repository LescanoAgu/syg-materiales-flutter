import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../providers/orden_interna_provider.dart';

class OrdenFormPage extends StatefulWidget {
  const OrdenFormPage({super.key});

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();

  // CORRECCIÓN: IDs ahora son String
  String? _clienteSeleccionadoId;
  String? _obraSeleccionadaId;
  DateTime _fechaSolicitud = DateTime.now();
  String _prioridad = 'normal';

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Orden Interna')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
    );
  }

  Widget _buildSelectorCliente() {
    return Card(
      child: Consumer<ClienteProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const LinearProgressIndicator();

          // Buscar cliente seleccionado por ID (String)
          final clienteSeleccionado = provider.clientes
              .where((c) => c.codigo == _clienteSeleccionadoId || c.id == _clienteSeleccionadoId)
              .firstOrNull;

          return ListTile(
            leading: const Icon(Icons.business, color: AppColors.primary),
            title: Text(clienteSeleccionado?.razonSocial ?? 'Seleccionar cliente'),
            subtitle: clienteSeleccionado != null ? Text('Código: ${clienteSeleccionado.codigo}') : const Text('Requerido'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _mostrarSelectorClientes(),
          );
        },
      ),
    );
  }

  Widget _buildSelectorObra() {
    return Card(
      child: Consumer<ObraProvider>(
        builder: (context, provider, child) {
          // Filtrar obras
          final obrasDelCliente = _clienteSeleccionadoId != null
              ? provider.obras.where((o) => o.clienteId == _clienteSeleccionadoId || o.clienteCodigo == _clienteSeleccionadoId).toList()
              : provider.obras;

          final obraSeleccionada = obrasDelCliente
              .where((o) => o.codigo == _obraSeleccionadaId || o.id == _obraSeleccionadaId)
              .firstOrNull;

          return ListTile(
            leading: const Icon(Icons.location_city, color: AppColors.primary),
            title: Text(obraSeleccionada?.nombre ?? 'Seleccionar obra'),
            subtitle: Text(obraSeleccionada?.codigo ?? 'Requerido'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (_clienteSeleccionadoId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero selecciona un cliente')));
                return;
              }
              _mostrarSelectorObras(obrasDelCliente);
            },
          );
        },
      ),
    );
  }

  // (Widgets de Fecha, Prioridad y Observaciones omitidos por brevedad, son iguales)
  // Solo incluyo los que cambian lógica.

  Widget _buildSelectorFecha() {
    return Card(
      child: ListTile(
        title: Text("Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSolicitud)}"),
        onTap: () async {
          final date = await showDatePicker(context: context, initialDate: _fechaSolicitud, firstDate: DateTime(2020), lastDate: DateTime(2030));
          if(date != null) setState(() => _fechaSolicitud = date);
        },
      ),
    );
  }

  Widget _buildSelectorPrioridad() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButton<String>(
          value: _prioridad,
          isExpanded: true,
          items: ['baja', 'normal', 'alta', 'urgente'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
          onChanged: (v) => setState(() => _prioridad = v!),
        ),
      ),
    );
  }

  Widget _buildCampoObservaciones() {
    return TextFormField(controller: _observacionesController, decoration: const InputDecoration(labelText: 'Observaciones'));
  }

  Widget _buildBotonCrear() {
    return ElevatedButton(
      onPressed: _validarYCrearOrden,
      child: const Text('Crear Orden Interna'),
    );
  }

  Future<void> _mostrarSelectorClientes() async {
    final clientes = context.read<ClienteProvider>().clientes;
    final seleccionado = await showDialog<String>( // Retorna String
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Clientes'),
        children: clientes.map((c) => SimpleDialogOption(
          child: Text(c.razonSocial),
          onPressed: () => Navigator.pop(context, c.codigo), // Usar código como ID
        )).toList(),
      ),
    );

    if (seleccionado != null) {
      setState(() {
        _clienteSeleccionadoId = seleccionado;
        _obraSeleccionadaId = null;
      });
      context.read<ObraProvider>().cargarObras();
    }
  }

  Future<void> _mostrarSelectorObras(List<dynamic> obras) async {
    final seleccionado = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Obras'),
        children: obras.map((o) => SimpleDialogOption(
          child: Text(o.nombre),
          onPressed: () => Navigator.pop(context, o.codigo), // Usar código como ID
        )).toList(),
      ),
    );

    if (seleccionado != null) {
      setState(() => _obraSeleccionadaId = seleccionado);
    }
  }

  Future<void> _validarYCrearOrden() async {
    if (_clienteSeleccionadoId == null || _obraSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faltan datos')));
      return;
    }

    // CORRECCIÓN CRÍTICA: Nombres de parámetros
    final exito = await context.read<OrdenInternaProvider>().crearOrden(
      clienteCodigo: _clienteSeleccionadoId!, // Cambiado de clienteId a clienteCodigo
      obraCodigo: _obraSeleccionadaId!,       // Cambiado de obraId a obraCodigo
      solicitanteNombre: 'Usuario Sistema',
      items: [],
      observaciones: _observacionesController.text,
      fechaSolicitud: _fechaSolicitud,
      prioridad: _prioridad,
    );

    if (exito && mounted) {
      Navigator.pop(context);
    }
  }
}