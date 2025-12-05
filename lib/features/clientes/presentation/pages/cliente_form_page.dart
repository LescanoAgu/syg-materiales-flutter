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

  String? _condicionIva;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.cliente?.codigo ?? '');
    _razonSocialCtrl = TextEditingController(text: widget.cliente?.razonSocial ?? '');
    _cuitCtrl = TextEditingController(text: widget.cliente?.cuit ?? '');
    _telefonoCtrl = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailCtrl = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionCtrl = TextEditingController(text: widget.cliente?.direccion ?? '');
    _localidadCtrl = TextEditingController(text: widget.cliente?.localidad ?? '');
    _condicionIva = widget.cliente?.condicionIva;

    if (widget.cliente == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nuevoCodigo = context.read<ClienteProvider>().generarNuevoCodigo();
        _codigoCtrl.text = nuevoCodigo;
      });
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _razonSocialCtrl.dispose();
    _cuitCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _localidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cliente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Datos Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Código',
                    controller: _codigoCtrl,
                    enabled: !esEdicion,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'CUIT',
                    controller: _cuitCtrl,
                    keyboardType: TextInputType.number,
                    hint: '30-12345678-9',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Razón Social / Nombre',
              controller: _razonSocialCtrl,
              prefixIcon: Icons.business,
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _condicionIva,
              decoration: const InputDecoration(
                labelText: 'Condición IVA',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'Responsable Inscripto', child: Text('Responsable Inscripto')),
                DropdownMenuItem(value: 'Monotributista', child: Text('Monotributista')),
                DropdownMenuItem(value: 'Exento', child: Text('Exento')),
                DropdownMenuItem(value: 'Consumidor Final', child: Text('Consumidor Final')),
              ],
              onChanged: (v) => setState(() => _condicionIva = v),
            ),
            const SizedBox(height: 24),
            const Text('Contacto y Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Teléfono',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Dirección',
              controller: _direccionCtrl,
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Localidad / Provincia',
              controller: _localidadCtrl,
              prefixIcon: Icons.map,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: Text(esEdicion ? 'GUARDAR CAMBIOS' : 'CREAR CLIENTE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nuevoCliente = ClienteModel(
      // ✅ CORRECCIÓN: Si id es null, pasamos string vacío (el repo creará uno nuevo)
      id: widget.cliente?.id ?? '',
      codigo: _codigoCtrl.text.trim(),
      razonSocial: _razonSocialCtrl.text.trim(),
      cuit: _cuitCtrl.text.trim(),
      condicionIva: _condicionIva,
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      localidad: _localidadCtrl.text.trim(),
      // ✅ CORRECCIÓN: 'activo' es bool, no string 'estado'
      activo: true,
      // ✅ CORRECCIÓN: Pasamos objetos DateTime, no Strings
      createdAt: widget.cliente?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<ClienteProvider>();
    bool exito;

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    if (widget.cliente != null) {
      exito = await provider.actualizarCliente(nuevoCliente);
    } else {
      exito = await provider.crearCliente(nuevoCliente);
    }

    if (mounted) {
      Navigator.pop(context);
      if (exito) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Operación exitosa'), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: ${provider.errorMessage}'), backgroundColor: AppColors.error));
      }
    }
  }
}