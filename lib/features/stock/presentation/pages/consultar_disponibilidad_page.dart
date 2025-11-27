import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';

class ConsultarDisponibilidadPage extends StatefulWidget {
  const ConsultarDisponibilidadPage({super.key});

  @override
  State<ConsultarDisponibilidadPage> createState() => _ConsultarDisponibilidadPageState();
}

class _ConsultarDisponibilidadPageState extends State<ConsultarDisponibilidadPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar productos al entrar para asegurar datos frescos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Consultar Disponibilidad')),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar material...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductoProvider>().buscarProductos('');
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => context.read<ProductoProvider>().buscarProductos(v),
            ),
          ),

          // Lista de resultados
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());
                if (prov.productos.isEmpty) return const Center(child: Text('No hay productos encontrados'));

                return ListView.separated(
                  itemCount: prov.productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (c, i) {
                    final p = prov.productos[i];
                    return _buildItem(p);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ProductoModel p) {
    // 🚦 LÓGICA DE SEMÁFORO
    Icon icono;
    Color colorTexto;
    String estadoTexto;

    if (p.cantidadDisponible <= 0) {
      // 🔴 SIN STOCK
      icono = const Icon(Icons.cancel, color: AppColors.error);
      colorTexto = AppColors.error;
      estadoTexto = "Sin Stock";
    } else if (p.stockBajo) { // Asumimos < 10
      // 🟠 STOCK BAJO
      icono = const Icon(Icons.warning, color: AppColors.warning);
      colorTexto = AppColors.warning;
      estadoTexto = "Bajo";
    } else {
      // 🟢 STOCK OK
      icono = const Icon(Icons.check_circle, color: AppColors.success);
      colorTexto = AppColors.textDark;
      estadoTexto = "OK";
    }

    return ListTile(
      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${p.codigo} • ${p.categoriaNombre ?? "Gral"}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                  '${p.cantidadFormateada} ${p.unidadBase}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTexto)
              ),
              Text(estadoTexto, style: TextStyle(fontSize: 10, color: colorTexto)),
            ],
          ),
          const SizedBox(width: 12),
          icono,
        ],
      ),
    );
  }
}