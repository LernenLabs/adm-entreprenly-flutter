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

  testWidgets('Buscar sin tildes ni mayúsculas encuentra el producto', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    for (final term in ['azucar', 'Azúcar', 'AZUCAR', ' azucar ']) {
      await tester.enterText(find.byType(TextField), term);
      await tester.pumpAndSettle();

      expect(
        find.text('Azúcar rubia'),
        findsOneWidget,
        reason: 'Término: "$term"',
      );
      expect(find.text('Arroz a granel'), findsNothing);
    }
  });

  testWidgets('Buscar un término sin resultados avisa al cliente', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos productos para "xyz".'), findsOneWidget);
    expect(find.text('Arroz a granel'), findsNothing);
    expect(find.text('Azúcar rubia'), findsNothing);
  });

  testWidgets('Vaciar la búsqueda vuelve a mostrar el catálogo', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.textContaining('No encontramos productos'), findsNothing);
    expect(find.text('Arroz a granel'), findsOneWidget);
    expect(find.text('Azúcar rubia'), findsOneWidget);
  });

  testWidgets('Un producto agotado sigue desactivado al buscarlo', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    for (final term in ['avena', 'AVENA', ' Avena ']) {
      await tester.enterText(find.byType(TextField), term);
      await tester.pumpAndSettle();

      expect(find.text('Avena'), findsOneWidget);
      expect(find.textContaining('Agotado'), findsOneWidget);
      expect(_addButton(tester, 'Avena').onPressed, isNull);
    }
  });

  testWidgets('Un producto disponible encontrado permite agregarlo', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'azucar');
    await tester.pumpAndSettle();

    expect(find.textContaining('Disponible'), findsOneWidget);
    expect(find.textContaining('Agotado'), findsNothing);
    expect(_addButton(tester, 'Azúcar rubia').onPressed, isNotNull);
  });
}

IconButton _addButton(WidgetTester tester, String name) {
  return tester.widget<IconButton>(
    find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Agregar $name',
    ),
  );
}
