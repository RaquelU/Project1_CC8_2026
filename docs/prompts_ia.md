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
---

## Versión 5 — Descubrimiento UDP y conexión de dos clientes

### Archivos relacionados

- `scripts/network/game_server.gd`
- `scripts/network/game_client.gd`
- `scripts/network/server_discovery.gd`
- `scenes/levels/game_world.tscn`

### Prompt utilizado

para la siguiente etapa que quiero implementar para mi proyecto, lo que necesito es poder hacer la parte de conexion completa, ya no solo utilizando tcp e ingresando de manera manual la direccion IP para conectarse, si no que ahora, implementando por completo las reglas aplicadas del protocolo diseñado por mis compañeros y yo, el cual te envie anteriormente. Necesito que siga al pie de la letra las reglas desarrolladas en ambos PDF. Lo que busco es poder tener una funcion bastante completa del funcionamiento esperado, sin implementar aun una interfaz (o UI) para el descubrimiento de servidor y demas, por el momento solo busco funcionamiento al 100%, por tanto puedo proponer que el servidor envie la informacion al cliente por medio de su terminal, y el cliente poder hacer un request de a qué servidor quiere conectarse. En otras palabras, debe cumplir con el protocolo dado en ambos PDF por medio de la terminal y no por una UI por el momento, esto con el fin de comprobar el funcionamiento de Godot y su lenguaje GDScript. Lo que quiero es que puedan haber mínimo 16 jugadores conectados (por el momento pueden ser 2 jugadores simultaneos y que comience el cooldown al conectarse) y que a la vez, los jugadores conectados puedan ver a los demas jugadores. Ese es mi objetivo en este momento. Ayudame

### Uso y modificaciones realizadas

El código generado se utilizó como base para ampliar la conexión cliente-servidor y agregar el descubrimiento automático de servidores.

Durante las pruebas se realizaron los siguientes ajustes:

- Se agregó un servidor UDP en el puerto `8888`.
- Se implementó el mensaje `discover`.
- Se implementó la respuesta `server_info`.
- Se agregó el script `server_discovery.gd`.
- El cliente puede encontrar servidores mediante broadcast UDP.
- Se mantuvo la conexión manual por IP como respaldo.
- Se configuró el inicio del countdown al conectarse dos jugadores.
- Se probaron dos clientes conectados al mismo servidor desde una sola computadora.
- Se comprobó que ambos clientes se conectaran y recibieran el inicio de partida.
- Se mantuvo TCP para la comunicación de la partida.
- La representación visual de los otros jugadores quedó pendiente para la siguiente etapa.

La prueba confirmó el descubrimiento UDP y la conexión simultánea de dos clientes. Todavía falta crear la representación visual de los jugadores remotos dentro del escenario 3D.

## Versión 6 — Adaptación al protocolo actualizado y prueba mediante VPN

### Archivos relacionados

- `scripts/network/game_server.gd`
- `scripts/network/game_client.gd`
- `scripts/network/server_discovery.gd`
- `scripts/player/player.gd`

### Prompt utilizado

bien, ahora partiendo desde la version 5, hubieron cambios ligeros en la implementacion del protocolo, por lo tanto el objetivo en este momento es que todo funcione con este nuevo enfoque. Obteniendo informacion de mis demas compañeros, la forma en que lo prueban es utilizando una VPN, ya que utilizando la red de nuestra universidad (Universidad Galileo) parece tener ciertas restricciones, entonces, el siguiente paso es llevar esta nueva version a que adapte todas las nuevas implementaciones y/o modificaciones del protocolo, para asegurarnos que todos puedan encontrar mi servidor, y yo como cliente puede encontrar el servidor de mis compañeros por medio de esa VPN, entonces, te hago envio del PDF y el link de repositorio de github para que puedas analizar y en base a eso implementar un codigo mucho mas robusto, optimo, limpio, entendible, y a un nivel de programador senior. Luego, haremos unas pruebas primero haciendo yo la prueba y luego hacer pruebas con mis demas compañeros. Asi tambien, al finalizar, quiero que me des opciones para asegurar que se pueda hacer la conexion y no tener problemas al intentarlo. https://github.com/citruspunch/cc8-2026-ctf-spec

### Uso y modificaciones realizadas

El código generado se utilizó como base para adaptar la versión 5 al protocolo actualizado de la clase.

Los cambios principales fueron:

- Se ajustó el ciclo completo de la partida: lobby, countdown, partida, fin y regreso automático al lobby.
- Se reforzó la validación de mensajes, fases, nombres, direcciones y tamaño máximo permitido.
- Se implementó el spawn aleatorio en el anillo definido por el protocolo.
- Se corrigió la lógica de captura, robo y victoria para que el servidor conserve toda la autoridad.
- Se mantuvo UDP únicamente para descubrimiento y TCP para toda la partida.
- Se agregó descubrimiento por broadcast, descubrimiento UDP unicast y conexión TCP directa como respaldo.
- Se mantuvo el manejo por terminal, sin interfaz gráfica.
- Se realizó una prueba entre dos computadoras conectadas (una amiga utilizando el mismo proyecto desde su casa) mediante ZeroTier, comprobando descubrimiento UDP unicast y conexión TCP al puerto anunciado.