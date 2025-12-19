import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';

class ClienteFormPage extends StatefulWidget {
  final ClienteModel? cliente;
  const ClienteFormPage({super.key, this.cliente});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codigoCtrl;
  late TextEditingController _razonSocialCtrl;
  late TextEditingController _cuitCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _localidadCtrl;

  @override
  void initState() {
    super.initState();
    // Si es nuevo, mostramos texto informativo
    String codigoInicial = widget.cliente?.codigo ?? 'Auto-generado (CL-XXX)';

    _codigoCtrl = TextEditingController(text: codigoInicial);
    _razonSocialCtrl = TextEditingController(text: widget.cliente?.razonSocial ?? '');
    _cuitCtrl = TextEditingController(text: widget.cliente?.cuit ?? '');
    _telefonoCtrl = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailCtrl = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionCtrl = TextEditingController(text: widget.cliente?.direccion ?? '');
    _localidadCtrl = TextEditingController(text: widget.cliente?.localidad ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Código',
                controller: _codigoCtrl,
                readOnly: true, // Siempre solo lectura
              ),
              const SizedBox(height: 16),
              CustomTextField(label: 'Razón Social / Nombre', controller: _razonSocialCtrl),
              const SizedBox(height: 16),
              CustomTextField(label: 'CUIT / DNI', controller: _cuitCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              CustomTextField(label: 'Teléfono', controller: _telefonoCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              CustomTextField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              CustomTextField(label: 'Dirección', controller: _direccionCtrl),
              const SizedBox(height: 16),
              CustomTextField(label: 'Localidad', controller: _localidadCtrl),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('GUARDAR CLIENTE'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (_razonSocialCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
      return;
    }

    final cliente = ClienteModel(
      id: widget.cliente?.id ?? '', // Si es '', el repo crea nuevo
      codigo: widget.cliente?.codigo ?? '', // Si es '', el repo genera CL-XXX
      razonSocial: _razonSocialCtrl.text,
      cuit: _cuitCtrl.text,
      email: _emailCtrl.text,
      telefono: _telefonoCtrl.text,
      direccion: _direccionCtrl.text,
      localidad: _localidadCtrl.text,
      activo: true,
      createdAt: widget.cliente?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<ClienteProvider>();
    // Guardar maneja internamente crear o actualizar
    final exito = await provider.guardarCliente(cliente);

    if (exito && mounted) Navigator.pop(context);
  }
}