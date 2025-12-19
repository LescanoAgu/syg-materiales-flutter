import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/obra_model.dart';
import 'obra_form_page.dart';

class ObraDetallePage extends StatelessWidget {
  final ObraModel obra;
  const ObraDetallePage({super.key, required this.obra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(obra.nombre),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ObraFormPage(obra: obra))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.business, color: AppColors.primary),
                  title: const Text("Cliente"),
                  subtitle: Text(obra.clienteRazonSocial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.map, color: AppColors.primary),
                  title: const Text("Ubicación"),
                  subtitle: Text(obra.direccion ?? "Sin dirección"),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person, color: AppColors.primary),
                  title: const Text("Contacto"),
                  subtitle: Text("${obra.nombreContacto ?? '-'} (${obra.telefonoContacto ?? '-'})"),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text("Inicio de Obra"),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(obra.fechaInicio)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Chip(
                    label: Text(obra.estado.toUpperCase()),
                    backgroundColor: obra.estado == 'activa' ? Colors.green.withValues(alpha: 0.2) : Colors.grey,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}