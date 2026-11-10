import 'package:entreprenly_compras/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('El cliente ajusta el carrito y revisa su pedido', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Agregar Arroz a granel'));
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar Arroz a granel'));
    await tester.pumpAndSettle();

    expect(find.text('S/ 9.60'), findsWidgets);
    await tester.tap(find.text('Revisar pedido'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('2 kg de Arroz a granel', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Copiar pedido'), findsOneWidget);
    expect(find.textContaining('Configura el WhatsApp'), findsNothing);
  });

  testWidgets('Buscar muestra productos agotados sin permitir agregarlos', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'avena');
    await tester.pumpAndSettle();

    expect(find.text('Avena'), findsOneWidget);
    expect(find.textContaining('Agotado'), findsOneWidget);
    expect(find.text('Arroz a granel'), findsNothing);
    final addButton = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Agregar Avena',
      ),
    );
    expect(addButton.onPressed, isNull);
  });
}
