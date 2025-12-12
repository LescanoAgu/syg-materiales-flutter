import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Importamos TU app real
import 'package:syg_materiales_flutter/app.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Construimos la app pasándole un home vacío para probar que arranca
    await tester.pumpWidget(const SyGMaterialesApp(home: Scaffold()));

    // Verificamos que se haya creado al menos un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}