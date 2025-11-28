import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';

class ProveedorFormPage extends StatefulWidget {
  final ProveedorModel? proveedor;
  const ProveedorFormPage({super.key, this.proveedor});

  @override
  State<ProveedorFormPage> createState() => _ProveedorFormPageState();
}

class _ProveedorFormPageState extends State<ProveedorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  // Por defecto externo, ya que el depósito S&G es fijo
  TipoProveedor _tipo = TipoProveedor.proveedor;

  @override
  void initState() {
    super.initState();
    if (widget.proveedor != null) {
      _codigoCtrl.text = widget.proveedor!.codigo;
      _nombreCtrl.text = widget.proveedor!.nombre;
      _telefonoCtrl.text = widget.proveedor!.telefono ?? '';
      _direccionCtrl.text = widget.proveedor!.direccion ?? '';
      _tipo = widget.proveedor!.tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.proveedor != null;
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar Proveedor' : 'Nuevo Proveedor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(labelText: 'Código (Ej: PRO-001)', border: OutlineInputBorder()),
                readOnly: esEdicion, // Código no editable
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre / Razón Social', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('GUARDAR'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = ProveedorModel(
      id: widget.proveedor?.id,
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      tipo: _tipo,
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      createdAt: widget.proveedor?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<AcopioProvider>();
    bool exito;

    if (widget.proveedor != null) {
      exito = await provider.actualizarProveedor(prov);
    } else {
      exito = await provider.crearProveedor(prov);
    }

    if (mounted && exito) Navigator.pop(context);
  }
}