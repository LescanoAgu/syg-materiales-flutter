import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import '../../../../core/constants/app_colors.dart';

class FirmaDigitalDialog extends StatefulWidget {
  const FirmaDigitalDialog({super.key});

  @override
  State<FirmaDigitalDialog> createState() => _FirmaDigitalDialogState();
}

class _FirmaDigitalDialogState extends State<FirmaDigitalDialog> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Firma de Recepción'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Firma en el recuadro para confirmar:'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Signature(
              controller: _controller,
              width: 300,
              height: 150,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _controller.clear(),
          child: const Text('Borrar', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white
          ),
          onPressed: () async {
            if (_controller.isNotEmpty) {
              final Uint8List? data = await _controller.toPngBytes();
              if (data != null && context.mounted) {
                Navigator.pop(context, data); // Retorna la imagen
              }
            }
          },
          child: const Text('CONFIRMAR'),
        ),
      ],
    );
  }
}