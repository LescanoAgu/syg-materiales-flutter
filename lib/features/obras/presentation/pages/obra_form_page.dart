import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  ClienteModel? _clienteSeleccionado;
  String _estado = 'activa';
  DateTime _fechaInicio = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
    });

    if (widget.obra != null) {
      _nombreCtrl.text = widget.obra!.nombre;
      _direccionCtrl.text = widget.obra!.direccion ?? '';
      _responsableCtrl.text = widget.obra!.nombreContacto ?? '';
      _telefonoCtrl.text = widget.obra!.telefonoContacto ?? '';
      _estado = widget.obra!.estado;
      _fechaInicio = widget.obra!.fechaInicio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.obra == null ? "Nueva Obra" : "Editar Obra"),
          backgroundColor: AppColors.primary
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Consumer<ClienteProvider>(
                builder: (ctx, prov, _) => DropdownButtonFormField<ClienteModel>(
                  value: _clienteSeleccionado,
                  decoration: const InputDecoration(labelText: "Cliente", border: OutlineInputBorder()),
                  items: prov.clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.razonSocial))).toList(),
                  onChanged: (v) => setState(() => _clienteSeleccionado = v),
                  validator: (v) => v == null && widget.obra == null ? 'Requerido' : null,
                  hint: widget.obra != null ? Text(widget.obra!.clienteRazonSocial) : const Text("Seleccione Cliente"),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(label: "Nombre de la Obra", controller: _nombreCtrl),
              const SizedBox(height: 16),
              CustomTextField(label: "Dirección", controller: _direccionCtrl),
              const SizedBox(height: 16),
              CustomTextField(label: "Nombre Contacto", controller: _responsableCtrl),
              const SizedBox(height: 16),
              CustomTextField(label: "Teléfono Contacto", controller: _telefonoCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha Inicio', border: OutlineInputBorder()),
                      child: Text(DateFormat('dd/MM/yyyy').format(_fechaInicio)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: _fechaInicio, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) setState(() => _fechaInicio = d);
                    },
                  )
                ],
              ),

              const SizedBox(height: 16),

              // ✅ SELECTOR DE ESTADO (Para poder archivar/finalizar obras)
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: "Estado Actual", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'activa', child: Text('🟢 Activa (En curso)')),
                  DropdownMenuItem(value: 'pausada', child: Text('⏸️ Pausada')),
                  DropdownMenuItem(value: 'finalizada', child: Text('🔴 Finalizada (Archivada)')),
                ],
                onChanged: (v) => setState(() => _estado = v!),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("GUARDAR OBRA"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final clienteId = _clienteSeleccionado?.id ?? widget.obra?.clienteId;
    final clienteNombre = _clienteSeleccionado?.razonSocial ?? widget.obra?.clienteRazonSocial;
    final clienteCod = _clienteSeleccionado?.codigo ?? widget.obra?.clienteCodigo;

    if (clienteId == null || clienteNombre == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Datos de cliente incompletos")));
      return;
    }

    final nuevaObra = ObraModel(
      id: widget.obra?.id ?? '',
      codigo: widget.obra?.codigo ?? 'O-${DateTime.now().millisecondsSinceEpoch}',
      nombre: _nombreCtrl.text,
      clienteId: clienteId!,
      clienteRazonSocial: clienteNombre!,
      clienteCodigo: clienteCod ?? '',
      direccion: _direccionCtrl.text,
      nombreContacto: _responsableCtrl.text,
      telefonoContacto: _telefonoCtrl.text,
      estado: _estado, // ✅ Se guarda el estado seleccionado
      fechaInicio: _fechaInicio,
    );

    await context.read<ObraProvider>().guardarObra(nuevaObra);
    if (mounted) Navigator.pop(context);
  }
}