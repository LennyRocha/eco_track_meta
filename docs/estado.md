# Gestión de estado — EcoTrack Meta

**Equipo:** Leonardo Obed Sanchez Rocha y Jonathan Alberto Barrera Calderon
**Fecha:** 26 de octubre de 2026

## Tipos de estado en nuestro código

| Dato | Tipo (efímero, compartido, derivado, persistido) | Dónde vive |
|---|---|---|
| Pestaña activa | Efímero: solo decide qué pestaña se muestra. | `_pestana` en `_PantallasEcoTrackState`; se modifica con `setState` y se usa como índice de `IndexedStack` en `lib/presentacion/vistas.dart`. |
| Texto del campo de litros | Efímero: pertenece al formulario y se limpia después de guardar. | `_litros`, un `TextEditingController` de `_FormularioRegistroState`, liberado en `dispose()` en `vistas.dart`. |
| consumos y meta | Compartido: las tres pestañas consultan el mismo dueño del estado. | `consumos` y `meta` en `ConsumosViewModel`, dentro de `lib/presentacion/consumos_view_model.dart`. |
| total y metaSuperada | Derivado: se calcula a partir de consumos y meta, sin guardar otro valor. | Los getters `total` y `metaSuperada` de `ConsumosViewModel`; `avance` también es un getter y utiliza `avanceDeMeta`. |
| Lo que regresa todos() | Persistido en memoria durante la ejecución: el repositorio conserva los registros y devuelve una copia no modificable. | `_consumos` y `List<Consumo>.unmodifiable(_consumos)` en `MemoriaConsumoRepository.todos()`, dentro de `lib/datos/memoria_consumo_repository.dart`. |

La implementación actual no guarda en disco: los consumos se pierden cuando
se destruye el repositorio o se reinicia la aplicación. La meta también vive
solo en memoria, en el ViewModel, y comienza en `metaInicial`.

El laboratorio seleccionado es otro estado efímero: `_laboratorio` pertenece
a `_FormularioRegistroState`. Las constantes `laboratoriosUtez` y `metaInicial`
son configuración fija; no son estado mutable. En cambio, el campo `meta`
sí cambia cuando se llama a `subirMeta()` o `bajarMeta()`.

## Criterios

| Criterio | A · ChangeNotifier puro | B · provider |
|---|---|---|
| Dato compartido | `_AppChangeNotifierState` crea un solo `_vm` y lo entrega a `RegistroCN`, `HistorialCN` y `MetaCN` en `a_change_notifier.dart`. | `ChangeNotifierProvider` crea una sola instancia de `ConsumosViewModel` para los tres adaptadores en `b_provider.dart`. |
| Capas | Las vistas reciben datos y callbacks; `vistas.dart` solo importa `material.dart` y `dominio/consumo.dart`, mientras que el ViewModel recibe el contrato `ConsumoRepository`. | Se reutilizan esas mismas vistas y el mismo ViewModel; `provider` se importa únicamente en `b_provider.dart`. |
| Encaje con el diagrama | El flujo es vista → callback → ViewModel → repositorio; el regreso se observa con `notifyListeners()` y los `ListenableBuilder` de los adaptadores CN. | El flujo conserva las mismas capas; `context.read<ConsumosViewModel>()` ejecuta acciones y `context.watch<ConsumosViewModel>()` escucha los cambios. |
| Constructores que reciben vm | Son tres: `RegistroCN`, `HistorialCN` y `MetaCN` declaran `required this.vm`. | Son cero: `RegistroProvider`, `HistorialProvider` y `MetaProvider` no reciben `vm`; lo obtienen del árbol. |
| Quién libera el ViewModel | El mismo dueño que lo crea: `_AppChangeNotifierState.dispose()` llama a `_vm.dispose()`. | `ChangeNotifierProvider` administra su liberación porque la instancia se construye en su callback `create`. |
| Costo de adoptarla ahora | No requiere otro paquete, pero hay que pasar el ViewModel por constructor y escribir un `ListenableBuilder` en cada adaptador. Evidencia: `a_change_notifier.dart`. | Requiere la dependencia `provider` de `pubspec.yaml`, un `ChangeNotifierProvider` y las llamadas `watch` y `read`; evita pasar `vm` por los constructores. Evidencia: `b_provider.dart`. |
| Sustitución de la fuente de datos | `AppChangeNotifier` recibe `ConsumoRepository`; `main_change_notifier.dart` es quien elige `MemoriaConsumoRepository`. Otra implementación del contrato se puede entregar por el mismo constructor. | `AppProvider` recibe el mismo contrato; `main.dart` elige `MemoriaConsumoRepository`. Se puede cambiar esa implementación sin modificar las vistas ni las reglas del dominio. |

## Elección

**Elegimos:** B · provider para el arranque principal. Las tres pestañas comparten
el estado y sus adaptadores lo consultan sin recibirlo por constructor.
La evidencia es `lib/main.dart`, que ejecuta `AppProvider`, y
`lib/variantes/b_provider.dart`, que utiliza `watch` para mostrar datos y `read`
en los callbacks para guardar y cambiar la meta. La variante A se conserva
en `lib/main_change_notifier.dart` para comparar ambos cableados.

**Se mantiene esta pieza del diagrama:** las vistas → `ConsumosViewModel` →
`ConsumoRepository` y las reglas de `dominio/`. Tanto los adaptadores CN como
los de provider importan `consumos_view_model.dart` y `vistas.dart`; cambia
la manera de entregar y escuchar el ViewModel, no esas piezas compartidas.

**Esta pieza es la que podría sustituirse después:** `MemoriaConsumoRepository`
por otra implementación de `ConsumoRepository`, por ejemplo una que guarde
en disco. El punto de cambio está en `main.dart` y `main_change_notifier.dart`,
donde se construye el repositorio. El ViewModel seguiría usando `guardar()` y
`todos()` a través del mismo contrato.
