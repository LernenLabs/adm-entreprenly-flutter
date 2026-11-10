import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

const _storeName = String.fromEnvironment(
  'STORE_NAME',
  defaultValue: 'Minimarket demo',
);
const _storePhone = String.fromEnvironment('STORE_WHATSAPP');
final _validStorePhone = RegExp(r'^[1-9][0-9]{7,14}$');

String _soles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

class _Product {
  const _Product(this.name, this.unit, this.price, this.stock, this.icon);

  final String name;
  final String unit;
  final int price;
  final int stock;
  final IconData icon;
}

// shortcut: catálogo de muestra, conectar al inventario antes de usarlo con clientes.
const _products = [
  _Product('Arroz a granel', 'kg', 480, 8, Icons.rice_bowl_outlined),
  _Product('Leche evaporada', 'unidad', 420, 12, Icons.local_drink_outlined),
  _Product('Azúcar rubia', 'kg', 390, 5, Icons.inventory_2_outlined),
  _Product('Aceite vegetal', 'unidad', 850, 6, Icons.water_drop_outlined),
  _Product('Avena', 'unidad', 320, 0, Icons.breakfast_dining_outlined),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFFF38313));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entreprenly Compras',
      theme: ThemeData(
        colorScheme: colors,
        scaffoldBackgroundColor: const Color(0xFFFBF8F5),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF38313),
            foregroundColor: const Color(0xFF0C0F12),
          ),
        ),
      ),
      home: const _Shop(),
    );
  }
}

class _Shop extends StatefulWidget {
  const _Shop();

  @override
  State<_Shop> createState() => _ShopState();
}

class _ShopState extends State<_Shop> {
  final _search = TextEditingController();
  final Map<_Product, int> _cart = {};
  int _tab = 0;

  int get _total => _cart.entries.fold(
    0,
    (total, item) => total + item.key.price * item.value,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _changeQuantity(_Product product, int change) {
    final quantity = (_cart[product] ?? 0) + change;
    if (quantity < 0 || quantity > product.stock) return;

    setState(() {
      if (quantity == 0) {
        _cart.remove(product);
      } else {
        _cart[product] = quantity;
      }
    });
  }

  Future<void> _reviewOrder() async {
    final message = [
      'Hola, quisiera pedir lo siguiente:',
      '',
      for (final item in _cart.entries)
        '- ${item.value} ${item.key.unit == 'kg'
            ? 'kg'
            : item.value == 1
            ? 'unidad'
            : 'unidades'} de ${item.key.name}',
      '',
      'Total estimado: ${_soles(_total)}.',
      '¿Me confirman disponibilidad y precio, por favor?',
    ].join('\n');
    final hasStorePhone = _validStorePhone.hasMatch(_storePhone);
    final action = await showDialog<_OrderAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revisa tu pedido'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(message),
              const SizedBox(height: 16),
              Text(
                hasStorePhone
                    ? 'Envía el mensaje desde WhatsApp para consultar con la tienda.'
                    : 'Configura el WhatsApp de la tienda para abrir el chat. También puedes copiar el pedido.',
              ),
            ],
          ),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final count = _cart.values.fold(0, (sum, quantity) => sum + quantity);
    return Scaffold(
      appBar: AppBar(title: const Text('Entreprenly Compras')),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _tab == 0 ? _catalog(context) : _basket(context),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Carrito',
          ),
        ],
      ),
    );
  }

  Widget _catalog(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = _products.where(
      (product) => product.name.toLowerCase().contains(query),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  'Catálogo de demostración',
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
            labelText: 'Buscar productos',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No encontramos productos con esa búsqueda.'),
          ),
        for (final product in matches) _productCard(product, inCart: false),
      ],
    );
  }

  Widget _basket(BuildContext context) {
    if (_cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Tu carrito está vacío',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => setState(() => _tab = 0),
                child: const Text('Ver catálogo'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Tu carrito', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final product in _cart.keys) _productCard(product, inCart: true),
        const SizedBox(height: 16),
        Text('Total estimado', style: Theme.of(context).textTheme.titleMedium),
        Text(_soles(_total), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('La tienda confirma la disponibilidad y el precio final.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _reviewOrder,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Revisar pedido'),
        ),
      ],
    );
  }

  Widget _productCard(_Product product, {required bool inCart}) {
    final quantity = _cart[product] ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(product.icon),
              title: Text(product.name),
              subtitle: Text(
                '${_soles(product.price)} / ${product.unit}\n'
                '${product.stock == 0 ? 'Agotado' : 'Disponible'}',
              ),
              isThreeLine: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (quantity > 0) ...[
                  IconButton(
                    tooltip: 'Quitar ${product.name}',
                    onPressed: () => _changeQuantity(product, -1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$quantity'),
                ],
                IconButton(
                  tooltip: 'Agregar ${product.name}',
                  onPressed: quantity < product.stock
                      ? () => _changeQuantity(product, 1)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                if (inCart) ...[
                  const SizedBox(width: 8),
                  Flexible(child: Text(_soles(product.price * quantity))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _OrderAction { copy, open }
