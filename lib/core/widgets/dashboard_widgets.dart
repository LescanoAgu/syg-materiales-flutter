import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/stock/data/models/producto_model.dart';
import 'producto_search_delegate.dart'; // Asegúrate que esta ruta sea correcta

/// Tarjeta genérica para el Dashboard
class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// SOLUCIÓN UX: Selector de producto tipo "Type-ahead"
/// Reemplaza al Dropdown limitado.
class ProductoSelectorField extends StatefulWidget {
  final Function(ProductoModel) onProductoSelected;
  final String label;

  const ProductoSelectorField({
    Key? key,
    required this.onProductoSelected,
    this.label = "Buscar Producto...",
  }) : super(key: key);

  @override
  State<ProductoSelectorField> createState() => _ProductoSelectorFieldState();
}

class _ProductoSelectorFieldState extends State<ProductoSelectorField> {
  final TextEditingController _controller = TextEditingController();
  ProductoModel? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            // Llama al SearchDelegate que ya tenías programado
            final result = await showSearch(
              context: context,
              delegate: ProductoSearchDelegate(),
            );

            if (result != null) {
              setState(() {
                _selectedProduct = result;
                _controller.text = "${result.codigo} - ${result.nombre}";
              });
              widget.onProductoSelected(result);
            }
          },
          child: IgnorePointer(
            // Ignora toques para que el InkWell maneje el evento
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: const OutlineInputBorder(),
                hintText: "Tocá para buscar...",
              ),
            ),
          ),
        ),
        if (_selectedProduct != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Text(
              "Stock actual: ${_selectedProduct!.cantidadFormateada} ${_selectedProduct!.unidadBase}",
              style: TextStyle(color: AppColors.textMedium, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
