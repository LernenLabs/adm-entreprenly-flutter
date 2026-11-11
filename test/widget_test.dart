import 'package:entreprenly_compras/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
    // La lista es perezosa: el tercer producto solo existe al desplazarse.
    await tester.scrollUntilVisible(
      find.text('Azúcar rubia'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

  group('Vista previa y salida a WhatsApp', () {
    testWidgets(
      'La vista previa lista cada producto con su unidad y el total',
      (tester) async {
        await _openOrderPreview(tester);

        expect(find.text(_twoProductOrder), findsOneWidget);
      },
    );

    testWidgets('Varias unidades se escriben en plural', (tester) async {
      await tester.pumpWidget(const MyApp());
      await _tapAdd(tester, 'Leche evaporada');
      await _tapAdd(tester, 'Leche evaporada');
      await tester.tap(find.text('Carrito'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar pedido'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('- 2 unidades de Leche evaporada'),
        findsOneWidget,
      );
      expect(find.textContaining('Total estimado: S/ 8.40.'), findsOneWidget);
    });

    testWidgets('Copiar pedido guarda el mensaje completo', (tester) async {
      final copied = _captureClipboard(tester);
      await _openOrderPreview(tester);

      await tester.tap(find.text('Copiar pedido'));
      await tester.pumpAndSettle();

      expect(copied, [_twoProductOrder]);
      expect(find.text('Pedido copiado.'), findsOneWidget);
    });

    testWidgets('Sin número de la tienda solo se ofrece copiar el pedido', (
      tester,
    ) async {
      await _openOrderPreview(tester);

      expect(find.text('Copiar pedido'), findsOneWidget);
      expect(find.text('Abrir WhatsApp'), findsNothing);
    }, skip: _hasStorePhone);

    testWidgets(
      'Con número de la tienda se abre el chat con el mensaje completo',
      (tester) async {
        final launcher = _FakeLauncher(opens: true);
        await _openOrderPreview(tester);

        await tester.tap(find.text('Abrir WhatsApp'));
        await tester.pumpAndSettle();

        expect(launcher.urls, hasLength(1));
        final url = Uri.parse(launcher.urls.single);
        expect(url.host, 'wa.me');
        expect(url.path, '/$_storePhone');
        expect(url.queryParameters['text'], _twoProductOrder);
        expect(find.textContaining('No se pudo abrir'), findsNothing);
      },
      skip: !_hasStorePhone,
    );

    testWidgets('Si el chat no abre, el pedido sigue disponible para copiar', (
      tester,
    ) async {
      _FakeLauncher(opens: false);
      final copied = _captureClipboard(tester);
      await _openOrderPreview(tester);

      await tester.tap(find.text('Abrir WhatsApp'));
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo abrir WhatsApp. Puedes copiar el pedido.'),
        findsOneWidget,
      );

      // Espera a que se oculte el aviso, que tapa el botón.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar pedido'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copiar pedido'));
      await tester.pumpAndSettle();

      expect(copied, [_twoProductOrder]);
    }, skip: !_hasStorePhone);
  });
}

const _storePhone = String.fromEnvironment('STORE_WHATSAPP');
final _hasStorePhone = RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(_storePhone);

const _twoProductOrder =
    'Hola, quisiera pedir lo siguiente:\n'
    '\n'
    '- 2 kg de Arroz a granel\n'
    '- 1 unidad de Leche evaporada\n'
    '\n'
    'Total estimado: S/ 13.80.\n'
    '¿Me confirman disponibilidad y precio, por favor?';

/// Agrega 2 kg de arroz y 1 leche, y abre «Revisar pedido».
Future<void> _openOrderPreview(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await _tapAdd(tester, 'Arroz a granel');
  await _tapAdd(tester, 'Arroz a granel');
  await _tapAdd(tester, 'Leche evaporada');
  await tester.tap(find.text('Carrito'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Revisar pedido'));
  await tester.pumpAndSettle();
}

/// Desplaza el catálogo hasta el botón de agregar y lo pulsa.
Future<void> _tapAdd(WidgetTester tester, String name) async {
  final button = find.byTooltip('Agregar $name');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

/// Registra los textos que la app copia al portapapeles.
List<String> _captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return copied;
}

/// Reemplaza el lanzador de enlaces y anota las URL que se intentan abrir.
class _FakeLauncher extends UrlLauncherPlatform {
  _FakeLauncher({required this.opens}) {
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = this;
    addTearDown(() => UrlLauncherPlatform.instance = original);
  }

  final bool opens;
  final urls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    return opens;
  }
}

IconButton _addButton(WidgetTester tester, String name) {
  return tester.widget<IconButton>(
    find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Agregar $name',
    ),
  );
}
