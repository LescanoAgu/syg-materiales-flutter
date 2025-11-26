import 'dart:async'; // <--- IMPORTANTE: Para el Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../providers/producto_provider.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'producto_detalle_page.dart';
import 'producto_form_page.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // <--- Variable para controlar el tiempo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Carga inicial rápida (limitada por el repositorio)
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancelar timer si se cierra la pantalla
    _searchController.dispose();
    super.dispose();
  }

  // Método mágico para no saturar la búsqueda
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Espera 800ms después de que el usuario deje de escribir
    _debounce = Timer(const Duration(milliseconds: 800), () {
      context.read<ProductoProvider>().buscarProductos(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Catálogo de Materiales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar Masivamente',
            onPressed: () => _mostrarDialogoImportacion(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductoProvider>().recargarProductos(),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductoFormPage()),
          ).then((_) => context.read<ProductoProvider>().cargarProductos());
        },
        label: const Text('Nuevo'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),

      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA OPTIMIZADA
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ProductoProvider>().limpiarBusqueda();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: _onSearchChanged, // <--- Usamos nuestro debouncer
            ),
          ),

          // 2. FILTROS
          _buildBarraFiltros(context),

          // 3. LISTA DE PRODUCTOS
          Expanded(
            child: Consumer<ProductoProvider>(
              builder: (ctx, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.productos.isEmpty) {
                  return _buildEstadoVacio();
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: provider.productos.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 70),
                  itemBuilder: (ctx, i) {
                    final p = provider.productos[i];
                    return _buildProductoItem(context, p);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (El resto de métodos _buildBarraFiltros, _buildProductoItem, _buildEstadoVacio, _mostrarDialogoImportacion quedan IGUAL que en la versión anterior)

  Widget _buildBarraFiltros(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Consumer<ProductoProvider>(
        builder: (context, provider, _) {
          final actual = provider.ordenActual;

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFiltroChip(
                context,
                label: 'Nombre A-Z',
                icon: Icons.sort_by_alpha,
                selected: actual == OrdenamientoCatalogo.nombreAZ,
                onSelected: () => provider.cambiarOrden(OrdenamientoCatalogo.nombreAZ),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                context,
                label: 'Nombre Z-A',
                icon: Icons.sort_by_alpha,
                selected: actual == OrdenamientoCatalogo.nombreZA,
                onSelected: () => provider.cambiarOrden(OrdenamientoCatalogo.nombreZA),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                context,
                label: 'Por Tipo',
                icon: Icons.category,
                selected: actual == OrdenamientoCatalogo.categoria,
                onSelected: () => provider.cambiarOrden(OrdenamientoCatalogo.categoria),
              ),
              const SizedBox(width: 8),
              _buildFiltroChip(
                context,
                label: 'Por Código',
                icon: Icons.tag,
                selected: actual == OrdenamientoCatalogo.codigo,
                onSelected: () => provider.cambiarOrden(OrdenamientoCatalogo.codigo),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFiltroChip(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool selected,
        required VoidCallback onSelected,
      }) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) Icon(icon, size: 16, color: Colors.white),
          if (selected) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textDark,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildProductoItem(BuildContext context, ProductoModel p) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductoDetallePage(producto: p)),
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(
          p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Text(
        p.nombre,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                p.codigo,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'RobotoMono',
                ),
              ),
            ),
            if (p.categoriaNombre != null) ...[
              const SizedBox(width: 8),
              Text(
                p.categoriaNombre!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${p.precioSinIva ?? '-'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          if (p.cantidadDisponible > 0)
            Text(
              'Stock: ${p.cantidadFormateada} ${p.unidadBase}',
              style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
            )
          else
            Text(
              'Sin Stock',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No hay materiales cargados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Usa el botón + para agregar uno nuevo'),
        ],
      ),
    );
  }

  // ... (Métodos de importación igual al anterior) ...
  void _mostrarDialogoImportacion(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importación Rápida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Formato CSV (una línea por producto):', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('CODIGO,NOMBRE,PRECIO,ID_CATEGORIA', style: TextStyle(fontFamily: 'Courier', fontSize: 12)),
            const SizedBox(height: 4),
            const Text('Ejemplo:', style: TextStyle(fontSize: 12)),
            const Text('MAT-01,Ladrillo,500,OG', style: TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Pega aquí tus datos...',
                fillColor: AppColors.backgroundGray,
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload),
            onPressed: () {
              _procesarImportacion(context, controller.text);
              Navigator.pop(ctx);
            },
            label: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  void _procesarImportacion(BuildContext context, String texto) {
    if (texto.isEmpty) return;

    List<ProductoModel> lista = [];
    try {
      final lineas = texto.split('\n');
      for (var linea in lineas) {
        if (linea.trim().isEmpty) continue;
        final partes = linea.split(',');
        if (partes.length >= 4) {
          lista.add(ProductoModel(
            codigo: partes[0].trim(),
            nombre: partes[1].trim(),
            precioSinIva: double.tryParse(partes[2].trim()),
            categoriaId: partes[3].trim(),
            unidadBase: 'u',
          ));
        }
      }

      if (lista.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Procesando...')),
        );
        context.read<ProductoProvider>().importarProductos(lista).then((success) {
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Éxito: ${lista.length} productos importados'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error: Revisa el formato del texto')),
      );
    }
  }
}