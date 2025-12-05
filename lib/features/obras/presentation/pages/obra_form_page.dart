import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';

class ObraFormPage extends StatefulWidget {
  final ObraModel? obra;
  const ObraFormPage({super.key, this.obra});

  @override
  State<ObraFormPage> createState() => _ObraFormPageState();
}

class _ObraFormPageState extends State<ObraFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codigoCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _responsableCtrl;
  late TextEditingController _telefonoCtrl;

  ClienteModel? _clienteSeleccionado;
  String _estado = 'activa';
  DateTime _fechaInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.obra?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.obra?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: widget.obra?.direccion ?? '');
    // ✅ Mapeo correcto a los nuevos campos
    _responsableCtrl = TextEditingController(text: widget.obra?.nombreContacto ?? '');
    _telefonoCtrl = TextEditingController(text: widget.obra?.telefonoContacto ?? '');
    _estado = widget.obra?.estado ?? 'activa';
    _fechaInicio = widget.obra?.fechaInicio ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      if (widget.obra == null) {
        _codigoCtrl.text = context.read<ObraProvider>().generarNuevoCodigo();
      } else {
        // Precargar cliente en edición
        try {
          final clientes = context.read<ClienteProvider>().clientes;
          // Buscamos por codigo o ID para ser seguros
          _clienteSeleccionado = clientes.firstWhere(
                  (c) => c.codigo == widget.obra!.clienteId || c.id == widget.obra!.clienteId
          );
          setState(() {});
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.obra == null ? 'Nueva Obra' : 'Editar Obra')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(label: 'Código', controller: _codigoCtrl, enabled: false),
            const SizedBox(height: 16),
            _buildSelectorCliente(),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nombre de Obra',
              controller: _nombreCtrl,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(label: 'Dirección', controller: _direccionCtrl),
            const SizedBox(height: 16),

            const Text('Contacto en Obra', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            CustomTextField(label: 'Nombre Responsable', controller: _responsableCtrl),
            const SizedBox(height: 8),
            CustomTextField(label: 'Teléfono', controller: _telefonoCtrl, keyboardType: TextInputType.phone),

            const SizedBox(height: 16),
            _buildSelectorEstado(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('GUARDAR OBRA'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorCliente() {
    return Consumer<ClienteProvider>(
      builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
        value: _clienteSeleccionado,
        decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
        items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
        onChanged: widget.obra == null ? (v) => setState(() => _clienteSeleccionado = v) : null,
      ),
    );
  }

  Widget _buildSelectorEstado() {
    return DropdownButtonFormField<String>(
      value: _estado,
      decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'activa', child: Text('Activa')),
        DropdownMenuItem(value: 'finalizada', child: Text('Finalizada')),
        DropdownMenuItem(value: 'pausada', child: Text('Pausada')),
      ],
      onChanged: (v) => setState(() => _estado = v!),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if(_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un cliente")));
      return;
    }

    final obra = ObraModel(
      // ✅ Si es nuevo, id es '', no null
      id: widget.obra?.id ?? '',
      codigo: _codigoCtrl.text,
      nombre: _nombreCtrl.text,
      clienteId: _clienteSeleccionado!.codigo, // Preferible usar ID, pero mantenemos código por consistencia
      clienteRazonSocial: _clienteSeleccionado!.razonSocial,
      clienteCodigo: _clienteSeleccionado!.codigo,
      direccion: _direccionCtrl.text,
      nombreContacto: _responsableCtrl.text,
      telefonoContacto: _telefonoCtrl.text,
      estado: _estado,
      fechaInicio: _fechaInicio,
    );

    // ✅ Usamos guardarObra (que unifica crear/actualizar)
    final exito = await context.read<ObraProvider>().guardarObra(obra);

    if (exito && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Guardado con éxito')));
    }
  }
}