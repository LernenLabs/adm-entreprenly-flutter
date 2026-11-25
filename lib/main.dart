import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog.dart';

void main() => runApp(MyApp());

const _storeName = String.fromEnvironment(
  'STORE_NAME',
  defaultValue: 'Minimarket demo',
);
const _storePhone = String.fromEnvironment('STORE_WHATSAPP');
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://adm-entreprenly-backend.onrender.com',
);
final _validStorePhone = RegExp(r'^[1-9][0-9]{7,14}$');

const _brandOrange = Color(0xFFF38313);
const _brandInk = Color(0xFF0C0F12);

/// Tamaño común de las fotos del catálogo y del carrito, para que todas las tarjetas se alineen.
const _photoSize = 72.0;

String _soles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

String _unitLabel(String unit, int quantity) {
  if (unit == 'kg') return 'kg';
  if (unit == 'unidad') return quantity == 1 ? 'unidad' : 'unidades';
  return unit;
}

const _accents = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
};

/// Texto en minúsculas, sin tildes y sin espacios sobrantes, para buscar.
String _normalize(String text) {
  final lower = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return lower.split('').map((char) => _accents[char] ?? char).join();
}

class MyApp extends StatelessWidget {
  /// [catalog] permite inyectar otro origen del catálogo (por ejemplo, en pruebas).
  MyApp({super.key, CatalogRepository? catalog})
    : catalog = catalog ?? HttpCatalogRepository(baseUrl: _apiBaseUrl);

  final CatalogRepository catalog;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: _brandOrange);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entreprenly Compras',
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xFFFBF8F5),
        // El naranja de la marca cubre también la barra de estado.
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandOrange,
          foregroundColor: _brandInk,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: _brandOrange,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandOrange,
            foregroundColor: _brandInk,
          ),
        ),
      ),
      home: _Shop(catalog: catalog),
    );
  }
}

class _Shop extends StatefulWidget {
  const _Shop({required this.catalog});

  final CatalogRepository catalog;

  @override
  State<_Shop> createState() => _ShopState();
}

enum _CatalogStatus { loading, ready, error }

class _ShopState extends State<_Shop> {
  final _search = TextEditingController();

  /// Cantidades del carrito por [CatalogProduct.key].
  final Map<String, int> _cart = {};
  List<CatalogProduct> _products = const [];
  _CatalogStatus _status = _CatalogStatus.loading;
  String _error = '';
  _ShopScreen _screen = _ShopScreen.catalog;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    if (_products.isEmpty) setState(() => _status = _CatalogStatus.loading);
    try {
      final products = await widget.catalog.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _products = products;
        _status = _CatalogStatus.ready;
        // Ajusta el carrito al stock actualizado y quita lo que ya no existe.
        final byKey = {for (final p in products) p.key: p};
        _cart.removeWhere((key, _) => byKey[key]?.isAvailable != true);
        for (final entry in _cart.entries.toList()) {
          final product = byKey[entry.key]!;
          if (!product.fits(entry.value)) {
            _cart[entry.key] = product.stock.floor();
          }
        }
        _cart.removeWhere((_, quantity) => quantity <= 0);
      });
    } on CatalogException catch (error) {
      if (!mounted) return;
      if (_products.isNotEmpty) {
        _notify(error.message);
        return;
      }
      setState(() {
        _status = _CatalogStatus.error;
        _error = error.message;
      });
    }
  }

  Map<CatalogProduct, int> get _cartItems {
    final byKey = {for (final p in _products) p.key: p};
    return {
      for (final entry in _cart.entries)
        if (byKey[entry.key] != null) byKey[entry.key]!: entry.value,
    };
  }

  int get _itemCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  int get _total => _cartItems.entries.fold(
    0,
    (total, item) => total + item.key.price * item.value,
  );

  void _showScreen(_ShopScreen screen) {
    if (screen == _screen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _screen = screen);
  }

  void _showCatalog() => _showScreen(_ShopScreen.catalog);

  void _changeQuantity(CatalogProduct product, int change) {
    final quantity = (_cart[product.key] ?? 0) + change;
    if (quantity < 0 || !product.fits(quantity)) return;

    setState(() {
      if (quantity == 0) {
        _cart.remove(product.key);
      } else {
        _cart[product.key] = quantity;
      }
    });
  }

  Future<void> _reviewOrder() async {
    final message = [
      'Hola, quisiera pedir lo siguiente:',
      '',
      for (final item in _cartItems.entries)
        '- ${item.value} ${_unitLabel(item.key.unit, item.value)} de ${item.key.name}',
      '',
      'Total estimado: ${_soles(_total)}.',
      '¿Me confirman disponibilidad y precio, por favor?',
    ].join('\n');
    final hasStorePhone = _validStorePhone.hasMatch(_storePhone);
    final action = await showDialog<_OrderAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisa tu pedido'),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(message),
            if (hasStorePhone) ...[
              const SizedBox(height: 16),
              const Text(
                'Envía el mensaje desde WhatsApp para consultar con la tienda.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _OrderAction.copy),
            child: const Text('Copiar pedido'),
          ),
          if (hasStorePhone)
            FilledButton(
              onPressed: () => Navigator.pop(context, _OrderAction.open),
              child: const Text('Abrir WhatsApp'),
            ),
        ],
      ),
    );
    if (!mounted || action == null) return;

    if (action == _OrderAction.copy) {
      await Clipboard.setData(ClipboardData(text: message));
      _notify('Pedido copiado.');
      return;
    }

    final url = Uri.https('wa.me', '/$_storePhone', {'text': message});
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // The system may not have an app that handles the link.
    }
    _notify('No se pudo abrir WhatsApp. Puedes copiar el pedido.');
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isCatalog = _screen == _ShopScreen.catalog;
    final count = _itemCount;
    final countLabel = '$count ${count == 1 ? 'ítem' : 'ítems'}';
    return PopScope<Object?>(
      canPop: isCatalog,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isCatalog) _showCatalog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _screen.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          toolbarHeight: 36 + MediaQuery.textScalerOf(context).scale(20),
          leading: isCatalog
              ? null
              : IconButton(
                  tooltip: 'Volver al catálogo',
                  onPressed: _showCatalog,
                  icon: const BackButtonIcon(),
                ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: isCatalog ? _catalog(context) : _basket(context),
            ),
          ),
        ),
        bottomNavigationBar: _ShopNavigation(
          selectedScreen: _screen,
          countLabel: countLabel,
          onSelected: _showScreen,
        ),
      ),
    );
  }

  Widget _catalog(BuildContext context) {
    switch (_status) {
      case _CatalogStatus.loading:
        return const _CatalogMessage(
          key: ValueKey('catalog-loading'),
          icon: null,
          title: 'Cargando catálogo…',
          message: 'La primera carga puede tardar unos segundos.',
        );
      case _CatalogStatus.error:
        return _CatalogMessage(
          key: const ValueKey('catalog-error'),
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar el catálogo',
          message: _error,
          actionLabel: 'Reintentar',
          onAction: _loadCatalog,
        );
      case _CatalogStatus.ready:
        break;
    }

    final rawQuery = _search.text.trim();
    final query = _normalize(rawQuery);
    final matches = _products.where(
      (product) =>
          _normalize(product.name).contains(query) ||
          _normalize(product.brand ?? '').contains(query),
    );
    return RefreshIndicator(
      onRefresh: _loadCatalog,
      child: ListView(
        key: const PageStorageKey(_ShopScreen.catalog),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: const Color(0xFFFFEBD7),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catálogo de la tienda',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storeName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arma tu pedido y consulta con la tienda por WhatsApp.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Buscar',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('La tienda todavía no publica productos.'),
            )
          else if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No encontramos productos para "$rawQuery".'),
            ),
          for (final product in matches) _productCard(product, inCart: false),
        ],
      ),
    );
  }

  Widget _basket(BuildContext context) {
    final items = _cartItems;
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Tu carrito está vacío',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _showCatalog,
                child: const Text('Ver catálogo'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      key: const PageStorageKey(_ShopScreen.cart),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final product in items.keys) _productCard(product, inCart: true),
        const SizedBox(height: 16),
        Text('Total estimado', style: Theme.of(context).textTheme.titleMedium),
        Text(_soles(_total), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('La tienda confirma la disponibilidad y el precio final.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _reviewOrder,
          child: const Text('Revisar pedido', textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _productCard(CatalogProduct product, {required bool inCart}) {
    final quantity = _cart[product.key] ?? 0;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductPhoto(product: product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: theme.textTheme.titleMedium),
                      if (product.brand != null)
                        Text(
                          product.brand!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text('${_soles(product.price)} / ${product.unit}'),
                      if (!product.isAvailable)
                        Text(
                          'Agotado',
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const Text('Disponible'),
                      if (!inCart && product.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (quantity > 0) ...[
                    IconButton(
                      tooltip: 'Quitar ${product.name}',
                      onPressed: () => _changeQuantity(product, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      inCart
                          ? '$quantity ${_unitLabel(product.unit, quantity)}'
                          : '$quantity',
                    ),
                  ],
                  IconButton(
                    tooltip: 'Agregar ${product.name}',
                    onPressed: product.fits(quantity + 1)
                        ? () => _changeQuantity(product, 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            if (inCart)
              Align(
                alignment: Alignment.centerRight,
                child: Text(_soles(product.price * quantity)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Foto del producto en un cuadrado fijo. Sin foto, o si falla, muestra un ícono.
class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.product});

  final CatalogProduct product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: const Color(0xFFFFEBD7),
      child: Center(
        child: Icon(
          product.unit == 'kg'
              ? Icons.scale_outlined
              : Icons.inventory_2_outlined,
          color: colors.primary,
        ),
      ),
    );
    final url = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: _photoSize,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: 'Foto de ${product.name}',
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

/// Estado de carga o de error del catálogo, centrado y con acción opcional.
class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Sin ícono se muestra un indicador de progreso.
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ShopScreen {
  catalog('Catálogo', Icons.storefront_outlined, Icons.storefront),
  cart('Carrito', Icons.shopping_bag_outlined, Icons.shopping_bag);

  const _ShopScreen(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShopNavigation extends StatelessWidget {
  const _ShopNavigation({
    required this.selectedScreen,
    required this.countLabel,
    required this.onSelected,
  });

  final _ShopScreen selectedScreen;
  final String countLabel;
  final ValueChanged<_ShopScreen> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          children: [
            for (final screen in _ShopScreen.values)
              Expanded(
                child: Semantics(
                  selected: screen == selectedScreen,
                  child: TextButton(
                    onPressed: () => onSelected(screen),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      backgroundColor: screen == selectedScreen
                          ? colors.secondaryContainer
                          : null,
                      foregroundColor: screen == selectedScreen
                          ? colors.onSecondaryContainer
                          : colors.onSurface,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          screen == selectedScreen
                              ? screen.selectedIcon
                              : screen.icon,
                        ),
                        Text(screen.label, textAlign: TextAlign.center),
                        if (screen == _ShopScreen.cart)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              countLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OrderAction { copy, open }
