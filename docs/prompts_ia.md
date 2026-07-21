# Registro de prompts utilizados con inteligencia artificial (ChatGPT, GPT-5.6 Sol, Nivel de Inteligencia Media)

## Versión 3 — Jugador y reglas locales

### Archivo relacionado

`scripts/player/player.gd`

### Prompt utilizado

Necesito que me ayudes a hacer el código del jugador para mi proyecto en Godot 4.7 usando GDScript. El nodo principal del jugador es un CharacterBody3D llamado Player y como nodos hijos un MeshInstance3D llamado PlayerMesh, un CapsuleShape3D llamado PlayerCollision y por ultimo un Node3D llamado CameraPivot con un nodo hijo Camera3D que lo llame PlayerCamera. Lo que necesito es que se pueda mover con W, A, S y D, que tenga gravedad y que no se caiga atravesando el suelo. También quiero que la cámara sea en primera persona y que pueda moverla con el mouse. Al presionar Escape (Esc) en el teclado, el mouse debería quedar libre otra vez. La velocidad del jugador debe ser de 20 unidades por segundo porque estamos usando una escala de 1:10 con el protocolo del proyecto acordado por mis compañeros hasta el momento (aunque puede cambiar en algun momento, las instrucciones enlazadas a este prompt son las que deben seguirse). También necesito que el jugador no pueda salir del mapa. El mapa mide 100 por 100 unidades y la posición del jugador debería mantenerse entre -48.5 y 48.5 en X y Z. Después necesito que pueda recoger la bandera presionando E, pero únicamente si está cerca. La distancia máxima debe ser de 4 unidades. Cuando el jugador tome la bandera, esta debe acompañarlo. Por último, quiero comprobar la condición de victoria de forma local. Si el jugador tiene la bandera y sale completamente del círculo central, debe aparecer un mensaje de victoria y detenerse. El círculo tiene radio 30 y el jugador radio 1.5, entonces debe ganar al superar una distancia de 31.5 desde el centro. Haz el código ordenado, usando funciones pequeñas y nombres fáciles de entender, de esta manera puedo entender mucho mejor el lenguaje del programa y asi poder modificar yo cosas en el si veo que puede simplificarse y quedarme con lo que me sirve, pero es para darme una idea en general ya que no conozco del todo el lenguaje.

### Uso y modificaciones realizadas

El código generado se utilizó como base para implementar `player.gd`.

Durante las pruebas se realizaron los siguientes ajustes:

- Se ajustó la posición de la cámara.
- Se ocultó la malla provisional del jugador para evitar verla desde la cámara.
- Se verificó el movimiento con teclado y mouse.
- Se probaron los límites del mapa.
- Se comprobó la captura de la bandera interactuando con el boton E.
- Se comprobó la condición local de victoria.

La validación de captura y victoria es provisional. En la implementación multijugador, estas reglas deberán ser confirmadas por el servidor, pero por el momento la implementación dada por la IA funciona y ayuda a comprender las bases para modificar posteriormente a la hora de pulir el proyecto.

## Versión 4 — Primera implementación de red TCP

### Archivos relacionados

- `scenes/network/server.tscn`
- `scripts/network/game_server.gd`
- `scripts/network/game_client.gd`
- `scripts/player/player.gd`
- `scenes/game_world.tscn`

### Prompt utilizado

lo que quiero implementar en este momento luego de que me dieras el codigo para player.gd y asi hacer pruebas de que godot esta funcionando perfectamente de manera local con las reglas establecidas que te indiqué, quiero ahora un codigo que implemente de la manera más óptima, sin tantas líneas de código pero lo más funcional posible (de manera que pueda ser entendible y de esta manera entienda lo que está pasando) para poder implementar el siguiente paso fundamental de este proyecto en Godot, entonces quiero que implementes lo requerido con el protocolo en desarrollo que tenemos con nuestros compañeros en conjunto, los cuales son esos dos PDF adjuntos, debes seguir al pie de la letra lo recomendado en esos archivos e implementarlo, de esta manera yo podré probar y ver qué cambios necesita y como mejorarlo. Tambien, dame una idea de cómo probarlo a pesar de no tener a nadie de manera local que pueda probarlo junto conmigo.

### Uso y modificaciones realizadas

El código generado se utilizó como base para comenzar la implementación de la comunicación entre cliente y servidor mediante TCP.

Durante las pruebas se realizaron los siguientes ajustes:

- Se creó la escena `server.tscn` para ejecutar el servidor de manera independiente.
- Se creó y conectó el script `game_server.gd`.
- Se agregó el nodo `NetworkClient` dentro de `game_world.tscn`.
- Se creó y conectó el script `game_client.gd`.
- Se configuró una conexión local mediante la dirección `127.0.0.1`.
- Se utilizó el puerto TCP `8889` para las pruebas.
- Se implementó el envío de mensajes en formato JSON.
- Se agregó el salto de línea `\n` como separador entre mensajes TCP.
- Se implementaron buffers para procesar mensajes completos, incompletos o recibidos juntos.
- Se implementó el mensaje `join` para registrar al jugador.
- Se verificó la recepción de los mensajes `welcome`, `lobby`, `countdown` y `start`.
- Se implementó el envío de la dirección de movimiento desde el cliente.
- Se modificó `player.gd` para que el jugador enviara su intención de movimiento en lugar de calcular directamente su posición.
- Se comprobó que el servidor calculara la posición oficial del jugador.
- Se mantuvo la conversión entre las coordenadas lógicas del protocolo y la escala 3D utilizada en Godot.
- Se comprobó que el jugador únicamente pudiera moverse después del mensaje `start`.
- Se verificó que la cámara en primera persona continuara funcionando.
- Se ejecutó el servidor desde PowerShell utilizando la versión de consola de Godot.
- Se realizó una prueba funcional con un servidor y un cliente en la misma computadora.

La implementación desarrollada en esta etapa corresponde a una primera prueba funcional de red mediante TCP. El servidor ya mantiene la autoridad sobre el movimiento y las reglas principales, mientras que el cliente envía sus acciones y muestra el estado recibido.

Por el momento, la prueba se realizó con un solo cliente conectado al servidor. La representación visual de otros jugadores, el descubrimiento mediante UDP y la conexión de varios clientes se dejaron pendientes para la siguiente etapa.