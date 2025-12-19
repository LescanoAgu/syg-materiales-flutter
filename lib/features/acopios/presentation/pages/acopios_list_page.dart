import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
// Corregimos la ruta del import
import '../../../clientes/presentation/pages/cliente_detalle_page.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../clientes/data/models/cliente_model.dart';
import 'acopio_form_page.dart'; // Para navegar a nuevo acopio

class AcopiosListPage extends StatefulWidget {
  const AcopiosListPage({super.key});

  @override
  State<AcopiosListPage> createState() => _AcopiosListPageState();
}

class _AcopiosListPageState extends State<AcopiosListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text("Billeteras de Materiales"),
        backgroundColor: AppColors.success,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.success,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar cliente...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),

          Expanded(
            child: Consumer<ClienteProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading)
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.success),
                  );

                final lista = prov.clientes
                    .where(
                      (c) => c.razonSocial.toLowerCase().contains(
                        _searchCtrl.text.toLowerCase(),
                      ),
                    )
                    .toList();

                if (lista.isEmpty)
                  return const Center(
                    child: Text("No se encontraron clientes"),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (ctx, i) {
                    final cliente = lista[i];
                    return _buildClienteCard(cliente);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AcopioFormPage()),
          );
        },
        label: const Text("Nuevo Acopio"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildClienteCard(ClienteModel cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClienteDetallePage(cliente: cliente),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                // ✅ Fix deprecated member usage
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.wallet,
                  color: AppColors.success,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.razonSocial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ver saldo y movimientos",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
