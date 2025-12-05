import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/main_layout.dart'; // Para el enum
import '../../../ordenes_internas/presentation/pages/ordenes_page.dart';
import '../../../ordenes_internas/presentation/pages/orden_form_page.dart';
import '../../../../core/enums/app_section.dart';

class JefeObraHomePage extends StatelessWidget {
  const JefeObraHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mis Obras')),
      drawer: const AppDrawer(currentSection: AppSection.ordenes), // Menú enfocado en órdenes

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdenFormPage())),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('NUEVO PEDIDO', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Column(
        children: [
          // 1. HEADER DE BIENVENIDA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hola, Jefe 👋", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("¿Qué materiales necesitas hoy?", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),

          // 2. ACCESO RÁPIDO A LISTA DE ÓRDENES
          // Aquí embebemos directamente la OrdenesPage o un resumen de ella.
          // Por simplicidad, usamos OrdenesPage pero con un filtro visual (que haremos luego).
          Expanded(
            child: const OrdenesPage(esNavegacionPrincipal: true),
          ),
        ],
      ),
    );
  }
}