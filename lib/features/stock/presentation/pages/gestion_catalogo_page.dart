import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import 'producto_form_page.dart';

class GestionCatalogoPage extends StatefulWidget {
  const GestionCatalogoPage({super.key});

  @override
  State<GestionCatalogoPage> createState() => _GestionCatalogoPageState();
}

class _GestionCatalogoPageState extends State<GestionCatalogoPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  // ✅ FILTRO AGREGADO
  String _categoriaSeleccionada = 'TODAS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProductoProvider>();
      p.cargarProductos(recargar: true);
      p.cargarCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ABM de Catálogo"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductoProvider>().cargarProductos(recargar: true),
          )
        ],
      ),
      body: Column(
        children: [
          // Buscador
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.purple,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Buscar para editar...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => context.read<ProductoProvider>().buscarProductos(val),
            ),
          ),

          // ✅ LISTA DE FILTROS DE CATEGORÍA
          Consumer<ProductoProvider>(
            builder: (ctx, prov, _) {
              final categorias = ['TODAS', ...prov.categorias.map((c) => c.nombre)];
              return SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: categorias.length,
                  separatorBuilder: (_,__) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = categorias[i];
                    final isSelected = _categoriaSeleccionada == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _categoriaSeleccionada = cat),
                      selectedColor: Colors.purple.withValues(alpha: 0.3),
                      labelStyle: TextStyle(color: isSelected ? Colors.purple : Colors.black),
                    );
                  },
                ),
              );
            },
          ),

          // Lista Filtrada
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, prov, _) {
                if (prov.isLoading) return const Center(child: CircularProgressIndicator());

                // ✅ LÓGICA DE FILTRADO
                List<ProductoModel> lista = prov.productos;
                if (_categoriaSeleccionada != 'TODAS') {
                  lista = lista.where((p) => p.categoriaNombre == _categoriaSeleccionada).toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_,__) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final p = lista[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withValues(alpha: 0.1),
                        child: Text(p.unidadBase.isNotEmpty ? p.unidadBase[0].toUpperCase() : '?', style: const TextStyle(color: Colors.purple)),
                      ),
                      title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${p.codigo} • ${p.categoriaNombre ?? 'Gral'}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoFormPage(producto: p))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: const Text("NUEVO PRODUCTO"),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductoFormPage())),
      ),
    );
  }
}