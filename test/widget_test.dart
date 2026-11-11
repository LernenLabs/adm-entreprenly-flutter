import 'package:entreprenly_compras/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  testWidgets('Navegación y pedido con texto al 200 % en 320 × 640', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    String? copiedOrder;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedOrder = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Finder title(String label) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(label));

    Future<void> tapVisible(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const MyApp());
    expect(title('Catálogo'), findsOneWidget);
    expect(find.text('0 ítems'), findsOneWidget);

    final cartTab = find.widgetWithText(TextButton, 'Carrito');
    await tapVisible(cartTab);
    expect(title('Carrito'), findsOneWidget);
    await tapVisible(find.widgetWithText(FilledButton, 'Ver catálogo'));

    final addMilk = find.byTooltip('Agregar Leche evaporada');
    await tester.scrollUntilVisible(
      addMilk,
      140,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tapVisible(addMilk);
    expect(find.text('1 ítem'), findsOneWidget);
    await tapVisible(addMilk);
    expect(find.text('2 ítems'), findsOneWidget);

    await tapVisible(cartTab);
    expect(title('Carrito'), findsOneWidget);
    expect(find.text('2 unidades'), findsOneWidget);
    await tapVisible(find.byTooltip('Volver al catálogo'));
    expect(title('Catálogo'), findsOneWidget);
    expect(find.text('2 ítems'), findsOneWidget);

    await tapVisible(cartTab);
    await tapVisible(find.byTooltip('Quitar Leche evaporada'));
    expect(find.text('1 unidad'), findsOneWidget);
    expect(find.text('1 ítem'), findsOneWidget);

    final review = find.widgetWithText(FilledButton, 'Revisar pedido');
    await tester.scrollUntilVisible(review, 120);
    await tapVisible(review);
    const phone = String.fromEnvironment('STORE_WHATSAPP');
    if (phone == '12025550123') {
      final launcher = _RecordingUrlLauncher();
      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await tapVisible(find.widgetWithText(FilledButton, 'Abrir WhatsApp'));
      expect(launcher.openedUrl?.host, 'wa.me');
      expect(launcher.openedUrl?.path, '/$phone');
      expect(
        launcher.openedUrl?.queryParameters['text'],
        contains('1 unidad de Leche evaporada'),
      );
      await tapVisible(review);
    }
    await tapVisible(find.widgetWithText(TextButton, 'Copiar pedido'));
    expect(copiedOrder, contains('1 unidad de Leche evaporada'));
    expect(copiedOrder, contains('S/ 4.20'));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(title('Catálogo'), findsOneWidget);
    expect(find.text('1 ítem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    expect(find.text('Leche evaporada'), findsOneWidget);
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

  testWidgets(
    'Al combinar 2 kg de arroz y 1 unidad de leche muestra subtotales, unidades y total de S/ 13.80',
    (tester) async {
      await tester.pumpWidget(const MyApp());

      await tester.tap(find.byTooltip('Agregar Arroz a granel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar Arroz a granel'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byTooltip('Agregar Leche evaporada'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agregar Leche evaporada'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();

      expect(find.text('2 kg'), findsOneWidget);
      expect(find.text('1 unidad'), findsOneWidget);

      expect(find.text('S/ 9.60'), findsOneWidget);
      expect(find.text('S/ 4.20'), findsOneWidget);
      expect(find.text('S/ 13.80'), findsOneWidget);
    },
  );

  testWidgets('Quitar la última unidad de un producto lo elimina del carrito', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Agregar Arroz a granel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Agregar Leche evaporada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar Leche evaporada'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();

    expect(find.text('Leche evaporada'), findsOneWidget);
    expect(find.text('1 unidad'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar Leche evaporada'));
    await tester.pumpAndSettle();

    expect(find.text('Leche evaporada'), findsNothing);
    expect(find.text('1 unidad'), findsNothing);
    expect(find.text('Arroz a granel'), findsOneWidget);

    await tester.tap(find.byTooltip('Quitar Arroz a granel'));
    await tester.pumpAndSettle();

    expect(find.text('Tu carrito está vacío'), findsOneWidget);
  });

  testWidgets(
    'El botón de agregar se desactiva al llegar al stock de muestra',
    (tester) async {
      await tester.pumpWidget(const MyApp());

      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byTooltip('Agregar Arroz a granel'));
        await tester.pumpAndSettle();
      }

      final addButton = _addButton(tester, 'Arroz a granel');
      expect(addButton.onPressed, isNull);

      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();

      expect(find.text('8 kg'), findsOneWidget);
      final addCartButton = _addButton(tester, 'Arroz a granel');
      expect(addCartButton.onPressed, isNull);
    },
  );
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  Uri? openedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    openedUrl = Uri.parse(url);
    return true;
  }
}

IconButton _addButton(WidgetTester tester, String name) {
  return tester.widget<IconButton>(
    find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Agregar $name',
    ),
  );
}
