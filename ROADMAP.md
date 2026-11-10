# Roadmap de Entreprenly Compras

Entreprenly Compras es la app Flutter para los clientes finales del segmento 2. Su recorrido principal va desde consultar productos de un comercio hasta recibir confirmación de un pedido.

## AV2 · 30 % del alcance propuesto

| Entregable | Peso | Evidencia |
| --- | ---: | --- |
| Catálogo de demostración | 10 % | Buscar productos, consultar el precio por unidad o kilo e identificar los agotados. |
| Carrito | 10 % | Agregar y quitar cantidades dentro del stock de muestra y revisar el total estimado. |
| Preparación del pedido | 10 % | Revisar y copiar el mensaje. Con el número de la tienda configurado, abrir el chat con el mensaje prellenado. |

Los porcentajes son una estimación por entregables para organizar el trabajo del equipo. La demo usa datos de muestra y el cliente envía la solicitud desde WhatsApp.

**Recorrido para exponer el AV2.** Buscar arroz, agregar 2 kg, revisar el total de S/ 9.60 y abrir la vista previa. Mostrar cómo se bloquea la adición de un producto agotado. Con el número de prueba del comercio configurado, mostrar el chat prellenado.

## Siguientes entregas · 70 % restante

| Entregable | Peso | Criterio de cierre |
| --- | ---: | --- |
| Catálogo conectado al backend | 20 % | Mostrar precios y disponibilidad del comercio seleccionado y cubrir los estados de carga, error y catálogo vacío. |
| Pedido de varios productos | 20 % | Registrar todas las líneas en un pedido que el comerciante pueda revisar desde su dashboard Kotlin. El backend valida precio y stock al registrar el pedido. |
| Confirmación para el cliente | 15 % | El cliente puede consultar el estado de su propio pedido y saber si el comercio lo confirmó. |
| Validación y entrega | 15 % | Probar el recorrido completo en Android y validar con clientes finales. Documentar el APK de entrega y la configuración de la tienda. |

## Trabajo en equipo

`main` contiene las versiones estables. Creen una rama por tarea desde `develop` actualizado y abran el pull request hacia `develop`.

```sh
git switch develop
git pull --ff-only origin develop
git switch -c feature/nombre-de-la-tarea
```
