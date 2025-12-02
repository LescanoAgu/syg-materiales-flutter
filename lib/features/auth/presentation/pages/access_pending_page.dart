import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AccessPendingPage extends StatelessWidget {
  const AccessPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthProvider>().usuario;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Solicitud Pendiente',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Hola ${usuario?.nombre ?? ""}, tu solicitud para unirte a la organización "${usuario?.organizationId}" ha sido enviada.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Un administrador debe aprobar tu cuenta y asignarte permisos antes de que puedas acceder.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
