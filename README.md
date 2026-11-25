# Entreprenly Compras

Versión inicial para el AV2. Los clientes finales pueden buscar productos de un minimarket de ejemplo, armar un carrito y preparar un mensaje para consultar el pedido por WhatsApp.

Consulta el [roadmap del AV2](ROADMAP.md) para ver el alcance del 30 % y las siguientes entregas.

## Ejecutar la demo

Requiere Flutter con Dart 3.13.7 o posterior en la serie 3.x.

```sh
flutter pub get
flutter run -d chrome
```

Para probar en Android, conecta un dispositivo o inicia un emulador y selecciónalo con `flutter run -d <id>`. Los dispositivos disponibles aparecen con `flutter devices`.

## Catálogo conectado al inventario

El catálogo se carga del inventario de la tienda con `GET /api/v1/public-catalog` (sin login). Por defecto usa el backend desplegado `https://adm-entreprenly-backend.onrender.com`. La primera carga puede tardar mientras el servidor despierta. Para un backend local:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8092
```

En el emulador de Android usa `http://10.0.2.2:8092`. La app muestra estados de carga, error con reintento y catálogo vacío; desliza hacia abajo para actualizar precios y stock.

## Configurar el WhatsApp de la tienda

Arranca la app con el nombre y el número autorizado de la tienda. Usa el número completo con el prefijo del país y solo dígitos. Sustituye `NUMERO_INTERNACIONAL` por ese número.

```sh
flutter run -d chrome --dart-define="STORE_NAME=Mi minimarket" --dart-define=STORE_WHATSAPP=NUMERO_INTERNACIONAL
```

Sin número configurado, el diálogo permite revisar y copiar el mensaje. Con un número válido, también permite abrir WhatsApp con el pedido prellenado. El cliente envía el mensaje desde el chat.

## Alcance de la demo

- El catálogo, los precios, las fotos y el stock vienen del inventario de la tienda demo. El carrito se conserva durante la sesión y se ajusta al stock al actualizar.
- El total es estimado. La tienda confirma disponibilidad y precio.
- El mensaje con varios productos está pensado para revisión del comercio. La creación automática del pedido en el bot y su visualización en el dashboard Kotlin requieren una integración adicional.

## Verificación

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```
