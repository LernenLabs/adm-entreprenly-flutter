# Entreprenly Compras

Versión inicial para el AV2. Los clientes finales pueden buscar productos de un minimarket de ejemplo, armar un carrito y preparar un mensaje para consultar el pedido por WhatsApp.

## Ejecutar la demo

Requiere Flutter con Dart 3.13.7 o posterior en la serie 3.x.

```sh
flutter pub get
flutter run -d chrome
```

Para probar en Android, conecta un dispositivo o inicia un emulador y selecciónalo con `flutter run -d <id>`. Los dispositivos disponibles aparecen con `flutter devices`.

## Configurar el WhatsApp de la tienda

Arranca la app con el nombre y el número autorizado de la tienda. Usa el número completo con el prefijo del país y solo dígitos. Sustituye `NUMERO_INTERNACIONAL` por ese número.

```sh
flutter run -d chrome --dart-define="STORE_NAME=Mi minimarket" --dart-define=STORE_WHATSAPP=NUMERO_INTERNACIONAL
```

Sin número configurado, el diálogo permite revisar y copiar el mensaje. Con un número válido, también permite abrir WhatsApp con el pedido prellenado. El cliente envía el mensaje desde el chat.

## Alcance de la demo

- El catálogo, los precios y el stock son de ejemplo. El carrito se conserva durante la sesión.
- El total es estimado. La tienda confirma disponibilidad y precio.
- El mensaje con varios productos está pensado para revisión del comercio. La creación automática del pedido en el bot y su visualización en el dashboard Kotlin requieren una integración adicional.

## Verificación

```sh
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```
