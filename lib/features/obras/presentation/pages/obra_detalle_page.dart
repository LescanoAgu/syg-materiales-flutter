import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ObraFormPage(obra: obra))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildInfoTile(Icons.person, "Cliente", obra.clienteRazonSocial),
            _buildInfoTile(Icons.location_on, "Dirección", obra.direccion ?? "-"),
            _buildInfoTile(Icons.phone, "Contacto en Obra", "${obra.nombreContacto ?? '-'} (${obra.telefonoContacto ?? '-'})"),
            _buildInfoTile(Icons.calendar_today, "Fecha Inicio", ArgFormats.fecha(obra.fechaInicio)),

            const SizedBox(height: 30),
            const Text("Ubicación (Mapa Próximamente)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.business, size: 40, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(obra.codigo, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(obra.estado.toUpperCase(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}