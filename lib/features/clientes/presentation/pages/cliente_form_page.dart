import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart'; // Usamos tus widgets
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';

class ClienteFormPage extends StatefulWidget {
  final ClienteModel? cliente; // Si es null, es CREACIÓN. Si tiene datos, es EDICIÓN.

  const ClienteFormPage({super.key, this.cliente});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _codigoCtrl;
  late TextEditingController _razonSocialCtrl;
  late TextEditingController _cuitCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _localidadCtrl;

  // Dropdowns
  String? _condicionIva;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos si estamos editando
    _codigoCtrl = TextEditingController(text: widget.cliente?.codigo ?? '');
    _razonSocialCtrl = TextEditingController(text: widget.cliente?.razonSocial ?? '');
    _cuitCtrl = TextEditingController(text: widget.cliente?.cuit ?? '');
    _telefonoCtrl = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailCtrl = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionCtrl = TextEditingController(text: widget.cliente?.direccion ?? '');
    _localidadCtrl = TextEditingController(text: widget.cliente?.localidad ?? '');

    _condicionIva = widget.cliente?.condicionIva;

    // Si es nuevo, generamos un código sugerido
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
            // Sección Principal
            const Text('Datos Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Código',
                    controller: _codigoCtrl,
                    // El código no se debería editar si ya existe para mantener integridad, o con cuidado
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

            // Botón Guardar
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
      // Si es edición, mantenemos el ID original. Si es nuevo, id es null (Firestore lo genera si usas .add, o usamos el código como ID)
      id: widget.cliente?.id,
      codigo: _codigoCtrl.text.trim(),
      razonSocial: _razonSocialCtrl.text.trim(),
      cuit: _cuitCtrl.text.trim(),
      condicionIva: _condicionIva,
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      localidad: _localidadCtrl.text.trim(),
      estado: 'activo',
      createdAt: widget.cliente?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final provider = context.read<ClienteProvider>();
    bool exito;

    // Mostrar loading
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    if (widget.cliente != null) {
      exito = await provider.actualizarCliente(nuevoCliente);
    } else {
      exito = await provider.crearCliente(nuevoCliente);
    }

    if (mounted) {
      Navigator.pop(context); // Cerrar loading

      if (exito) {
        Navigator.pop(context); // Volver a la lista
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Operación exitosa'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${provider.errorMessage}'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}