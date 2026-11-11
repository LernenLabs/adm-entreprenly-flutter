# Validación de Catálogo y Carrito

| Parámetro | Valor |
| --- | --- |
| Fecha | 11 de noviembre de 2026 |
| Emulador | Pixel 7 Pro, Android 15 (API 35) |
| Pantalla de prueba | 320 × 640 px a 160 dpi, equivalentes a 320 × 640 dp |
| Tamaño de texto | 200 % en los ajustes de Android (`font_scale=2.0`) |
| SDK | Flutter 3.47.9, Dart 3.13.7 |

## Capturas

1. [Catálogo](01-catalogo.png). Al volver desde el carrito, el contador sigue indicando «2 ítems».
2. [Carrito](02-carrito.png). Tras quitar una unidad, el contador indica «1 ítem» y el subtotal se actualiza a S/ 4.20.
3. [Total y revisión](03-total.png). Al desplazar el carrito se puede consultar el total y tocar «Revisar pedido».
4. [Vista previa](04-revision.png). El mensaje se puede desplazar y las acciones para volver, copiar y abrir WhatsApp quedan visibles.

## Repetir la prueba

En un emulador Android de pruebas, aplicar estos ajustes antes de abrir la app.

```sh
adb shell wm size 320x640
adb shell wm density 160
adb shell settings put system font_scale 2.0
flutter run -d <id-del-emulador> --dart-define=STORE_WHATSAPP=12025550123
```

Agregar dos unidades de leche evaporada, abrir el carrito y volver al catálogo. Confirmar que el contador sigue indicando «2 ítems». Abrir el carrito otra vez, quitar una unidad y revisar el pedido. Confirmar que el contador indica «1 ítem» y que se puede copiar el pedido.

El número de ejemplo habilita la acción de WhatsApp para la captura. La prueba automatizada simula el lanzamiento y verifica el número y el pedido prellenado.

```sh
flutter analyze
flutter test
flutter test --dart-define=STORE_WHATSAPP=12025550123
```
