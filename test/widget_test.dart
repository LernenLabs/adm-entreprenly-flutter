import 'dart:convert';

import 'package:entreprenly_compras/catalog.dart';
import 'package:entreprenly_compras/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    await _pumpShop(tester);
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
    await _pumpShop(tester);

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
    await _pumpShop(tester);
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
    await _pumpShop(tester);

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
    await _pumpShop(tester);
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos productos para "xyz".'), findsOneWidget);
    expect(find.text('Arroz a granel'), findsNothing);
    expect(find.text('Azúcar rubia'), findsNothing);
  });

  testWidgets('Vaciar la búsqueda vuelve a mostrar el catálogo', (
    tester,
  ) async {
    await _pumpShop(tester);
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
    await _pumpShop(tester);

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
    await _pumpShop(tester);
    await tester.enterText(find.byType(TextField), 'azucar');
    await tester.pumpAndSettle();

    expect(find.textContaining('Disponible'), findsOneWidget);
    expect(find.textContaining('Agotado'), findsNothing);
    expect(_addButton(tester, 'Azúcar rubia').onPressed, isNotNull);
  });

  testWidgets(
    'Al combinar 2 kg de arroz y 1 unidad de leche muestra subtotales, unidades y total de S/ 13.80',
    (tester) async {
      await _pumpShop(tester);

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
    await _pumpShop(tester);

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
      await _pumpShop(tester);

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

  testWidgets('Muestra la descripción y la marca que vienen del inventario', (
    tester,
  ) async {
    await _pumpShop(tester);
    await tester.enterText(find.byType(TextField), 'leche');
    await tester.pumpAndSettle();

    expect(find.text('Gloria'), findsOneWidget);
    expect(find.text('Lata de 400 g, ideal para el desayuno.'), findsOneWidget);
  });

  testWidgets('Si el catálogo falla muestra el error y permite reintentar', (
    tester,
  ) async {
    final catalog = _FakeCatalog(_sampleProducts, failuresBeforeSuccess: 1);
    await tester.pumpWidget(MyApp(catalog: catalog));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar el catálogo'), findsOneWidget);
    expect(find.text('Sin conexión de prueba.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Arroz a granel'), findsOneWidget);
    expect(catalog.calls, 2);
  });

  testWidgets('Un catálogo vacío avisa que la tienda no tiene productos', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(catalog: _FakeCatalog(const [])));
    await tester.pumpAndSettle();

    expect(
      find.text('La tienda todavía no publica productos.'),
      findsOneWidget,
    );
  });

  test('El repositorio HTTP lee el catálogo público del backend', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode([
            {
              'id': 7,
              'productType': 'weight',
              'name': 'Limón',
              'description': 'Limón sutil jugoso.',
              'brand': null,
              'imageUrl': 'https://example.com/limon.jpg',
              'price': 6.0,
              'unit': 'kg',
              'stock': 4.5,
              'available': true,
            },
          ]),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = HttpCatalogRepository(
      baseUrl: 'https://api.example.com/',
      client: client,
    );

    final products = await repository.fetchCatalog();

    expect(
      requested.toString(),
      'https://api.example.com/api/v1/public-catalog',
    );
    expect(products, hasLength(1));
    final lemon = products.single;
    expect(lemon.key, 'weight/7');
    expect(lemon.name, 'Limón');
    expect(lemon.unit, 'kg');
    expect(lemon.price, 600);
    expect(lemon.fits(4), isTrue);
    expect(lemon.fits(5), isFalse);
    expect(lemon.imageUrl, 'https://example.com/limon.jpg');
  });

  test('El repositorio HTTP traduce un error del servidor', () async {
    final repository = HttpCatalogRepository(
      baseUrl: 'https://api.example.com',
      client: MockClient((_) async => http.Response('boom', 503)),
    );

    expect(
      repository.fetchCatalog(),
      throwsA(
        isA<CatalogException>().having(
          (e) => e.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });
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

const _sampleProducts = [
  CatalogProduct(
    id: 1,
    type: 'weight',
    name: 'Arroz a granel',
    unit: 'kg',
    price: 480,
    stock: 8,
  ),
  CatalogProduct(
    id: 1,
    type: 'unit',
    name: 'Leche evaporada',
    brand: 'Gloria',
    description: 'Lata de 400 g, ideal para el desayuno.',
    unit: 'unidad',
    price: 420,
    stock: 12,
  ),
  CatalogProduct(
    id: 2,
    type: 'weight',
    name: 'Azúcar rubia',
    unit: 'kg',
    price: 390,
    stock: 5,
  ),
  CatalogProduct(
    id: 2,
    type: 'unit',
    name: 'Aceite vegetal',
    unit: 'unidad',
    price: 850,
    stock: 6,
  ),
  CatalogProduct(
    id: 3,
    type: 'unit',
    name: 'Avena',
    unit: 'unidad',
    price: 320,
    stock: 0,
  ),
];

/// Catálogo en memoria; puede fallar las primeras [failuresBeforeSuccess] veces.
class _FakeCatalog implements CatalogRepository {
  _FakeCatalog(this.products, {this.failuresBeforeSuccess = 0});

  final List<CatalogProduct> products;
  int failuresBeforeSuccess;
  int calls = 0;

  @override
  Future<List<CatalogProduct>> fetchCatalog() async {
    calls++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw const CatalogException('Sin conexión de prueba.');
    }
    return products;
  }
}

Future<void> _pumpShop(WidgetTester tester) async {
  await tester.pumpWidget(MyApp(catalog: _FakeCatalog(_sampleProducts)));
  await tester.pumpAndSettle();
}
