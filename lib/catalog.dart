import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Producto del catálogo público de la tienda, tal como lo publica el inventario.
class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.type,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    this.description,
    this.brand,
    this.imageUrl,
  });

  /// Crea el producto desde un elemento de `GET /api/v1/public-catalog`.
  ///
  /// Las fotos subidas desde la app llegan como ruta relativa
  /// (`/api/v1/inventory-product-images/…`); [baseUri] la convierte en URL completa.
  factory CatalogProduct.fromJson(Map<String, dynamic> json, {Uri? baseUri}) {
    final type = json['productType'] as String? ?? 'unit';
    final rawPrice = (json['price'] as num?)?.toDouble() ?? 0;
    return CatalogProduct(
      id: (json['id'] as num).toInt(),
      type: type,
      name: (json['name'] as String? ?? '').trim(),
      description: _text(json['description']),
      brand: _text(json['brand']),
      imageUrl: _imageUrl(_text(json['imageUrl']), baseUri),
      unit: _text(json['unit']) ?? (type == 'weight' ? 'kg' : 'unidad'),
      price: (rawPrice * 100).round(),
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
    );
  }

  final int id;

  /// `unit` (por unidad) o `weight` (por kilo). Junto con [id] identifica al producto.
  final String type;
  final String name;
  final String? description;
  final String? brand;
  final String? imageUrl;

  /// `unidad` o `kg`.
  final String unit;

  /// Precio en céntimos por [unit].
  final int price;

  /// Stock disponible en unidades o kilos.
  final double stock;

  String get key => '$type/$id';

  bool get isAvailable => stock > 0;

  /// Indica si caben [quantity] unidades o kilos dentro del stock.
  bool fits(int quantity) => quantity <= stock + 1e-9;

  static String? _imageUrl(String? value, Uri? baseUri) {
    if (value == null || !value.startsWith('/')) return value;
    return baseUri?.resolve(value).toString() ?? value;
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Origen del catálogo. La app usa [HttpCatalogRepository]; las pruebas, uno en memoria.
abstract interface class CatalogRepository {
  Future<List<CatalogProduct>> fetchCatalog();
}

/// Error al cargar el catálogo, con un mensaje listo para mostrar al cliente.
class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lee el catálogo del inventario desde el backend de Entreprenly.
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  Uri get catalogUri => Uri.parse(baseUrl).resolve('/api/v1/public-catalog');

  @override
  Future<List<CatalogProduct>> fetchCatalog() async {
    final http.Response response;
    try {
      response = await _client
          .get(catalogUri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const CatalogException(
        'La tienda tardó demasiado en responder. Intenta de nuevo.',
      );
    } on Exception {
      throw const CatalogException(
        'No pudimos conectarnos con la tienda. Revisa tu conexión.',
      );
    }
    if (response.statusCode != 200) {
      throw CatalogException(
        'La tienda no pudo enviar su catálogo (error ${response.statusCode}).',
      );
    }
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return [
        for (final item in data)
          CatalogProduct.fromJson(
            item as Map<String, dynamic>,
            baseUri: Uri.parse(baseUrl),
          ),
      ];
    } on Object {
      throw const CatalogException('El catálogo recibido no es válido.');
    }
  }
}
