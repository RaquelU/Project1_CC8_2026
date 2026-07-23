# Bitácora de desarrollo

## Versión 1 - Configuración inicial

**Estado:** Completada  
**Commit:** `chore: configurar estructura inicial del proyecto Godot`  

### Cambios realizados

- Se creó el repositorio local `Project1_CC8_2026` con GitHub Desktop.
- Se creó el proyecto en Godot Engine 4.7 Stable.
- Se configuró el archivo `.gitignore`.
- Se crearon las carpetas básicas del proyecto.
- Se creó esta bitácora para registrar el avance.

### Decisiones

- Lenguaje: GDScript.
- Motor: Godot Engine 4.7 Stable.
- Entorno: 3D.
- Comunicación prevista: sockets básicos.

### Cambios de idea

No hubo cambios de idea.

---

## Versión 2 - Primera versión visual 3D

**Estado:** Completada  
**Commit:** `feat: crear primera versión visual 3D del escenario` 

### Cambios realizados

- Se creó la escena principal `GameWorld`.
- Se creó el suelo con `StaticBody3D`, `MeshInstance3D` y `CollisionShape3D`.
- Se agregó iluminación direccional y ambiente básico.
- Se agregó una cámara temporal.
- Se creó el círculo central con radio físico de 30 unidades.
- Se creó una bandera provisional en el centro del mapa.
- Se adaptó el mapa lógico de 1000 x 1000 a una escala 1:10 en Godot.

### Prueba

La escena se ejecutó correctamente y se visualizaron el suelo, la iluminación, la cámara, el círculo y la bandera. La colisión del suelo será probada al implementar el jugador.

La evidencia de esta prueba se guardó en:

`tests/evidence/greybox_v0.2.0.png`

### Cambios de idea

No hubo cambios de idea. Desde el inicio se decidió trabajar en Godot 3D con GDScript y seguir el protocolo que está siendo definido por la clase.

### Próxima versión

Crear el jugador provisional, implementar movimiento local y probar la colisión con el suelo.

## Versión 3 - Jugador y reglas locales

**Estado:** Completada  
**Commit:** `feat: implementar jugador y reglas locales de prueba`

### Cambios realizados

- Se creó una escena `Player` con `CharacterBody3D`.
- Se implementó movimiento, gravedad y colisión con el suelo.
- Se configuró una cámara en primera persona.
- Se limitaron las posiciones del jugador al área del mapa.
- Se agregó interacción local con la bandera mediante la tecla `E`.
- Se agregó validación local de victoria al salir completamente del círculo con la bandera.
- Se guardó una captura de la prueba funcional en `tests/evidence/`.

### Cambios de idea

No hubo cambios de idea. Desde el inicio se tenia la idea clara de utilizar el jugador en primera persona para mayor inmersion

### Consideración para la red

La captura y la victoria funcionan localmente para comprobar las reglas. Cuando se implemente la red, estas validaciones serán realizadas por el servidor.

El archivo relacionado a esta parte se encuentra en:

`tests/evidence/prototipo_funcional_v0.3.0.png`

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para generar una base del script `scripts/player/player.gd`.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_player_script_1.png`

---

## Versión 4 - Primera implementación de red TCP

**Estado:** Completada para prueba local con un cliente  
**Commit:** `feat: implementar primera conexion TCP cliente-servidor`

### Cambios realizados 

- Se creó la escena `scenes/network/server.tscn`.
- Se creó el script `scripts/network/game_server.gd`.
- Se creó el nodo `NetworkClient` dentro de `game_world.tscn`.
- Se creó el script `scripts/network/game_client.gd`.
- Se implementó una conexión TCP manual usando la dirección local `127.0.0.1`.
- Se configuró el puerto TCP `8889` para las pruebas.
- Se utilizaron mensajes JSON codificados en UTF-8.
- Cada mensaje TCP se separa mediante un salto de línea `\n`.
- Se agregó un buffer para conservar mensajes incompletos o procesar varios mensajes recibidos juntos.
- Se implementaron los mensajes `join`, `input` e `interact` enviados por el cliente.
- Se implementaron respuestas básicas del servidor como `welcome`, `lobby`, `countdown`, `start`, `state`, `game_over` y `error`.
- El cliente envía únicamente la intención de movimiento.
- El servidor normaliza la dirección, calcula la posición oficial y aplica los límites del mapa.
- El servidor valida la captura de la bandera, la interacción y la condición de victoria.
- El cliente convierte las coordenadas lógicas del protocolo a la escala 3D usada en Godot.
- Se mantuvo la cámara en primera persona y el control con teclado y mouse.
- Se configuró el servidor para aceptar hasta 100 conexiones, de acuerdo con el protocolo.

### Valores utilizados

- Versión del protocolo: `1`.
- Puerto TCP de prueba: `8889`.
- Mapa lógico: `1000 x 1000`.
- Velocidad lógica: `200` unidades por segundo.
- Radio lógico del jugador: `15`.
- Radio lógico del círculo: `300`.
- Distancia lógica de interacción: `40`.
- Frecuencia de envío del estado: `20` veces por segundo.
- Escala visual en Godot: `1:10`.

### Prueba realizada

La prueba se realizó en una sola computadora:

1. Se ejecutó `server.tscn` mediante la versión de consola de Godot.
2. El servidor mostró que inició correctamente en el puerto `8889`.
3. Se ejecutó `game_world.tscn` como cliente.
4. El cliente se conectó a `127.0.0.1`.
5. El servidor asignó un identificador al jugador.
6. Se recibió la cuenta regresiva y el mensaje de inicio.
7. Después del inicio, el jugador pudo moverse utilizando el estado enviado por el servidor.
8. La cámara en primera persona continuó funcionando correctamente.

La evidencia de esta prueba se guardó en:

`tests/evidence/prueba_conexion_tcp_1.png`

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para generar una base sólida del script `scripts/network/game_server.gd`,
`scripts/network/game_client.gd` y asi poder modificar correctamente el script del jugador `scripts/player/player.gd`.
La razon de uso literal del script es solo para hacer pruebas y entender el comportamiento de godot y su lenguaje GDScript
para implementar una mejor opcion y de ser posible, mucho más óptima posterior para el juego finalizado una vez entendido
lo suficiente el lenguaje de programación y cómo funciona la comunicación con TCP cliente-servidor en este motor gráfico.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_implementacion_red_1.png`

### Resultado

Se comprobó que existe comunicación funcional entre un servidor y un cliente mediante TCP. El servidor mantiene la autoridad de la posición y el cliente muestra el estado recibido.

### Limitaciones actuales

- La conexión se realiza manualmente usando `127.0.0.1`.
- Todavía no se ha implementado el descubrimiento de servidores mediante UDP.
- Todavía no se ha creado una interfaz para escribir o seleccionar una dirección IP.
- La prueba documentada se realizó con un solo cliente.
- Aunque el servidor puede aceptar más conexiones, todavía no se muestran jugadores remotos dentro del escenario 3D.
- No se ha probado aún la captura o el robo entre dos jugadores visibles.
- La interfaz de lobby y los mensajes de red todavía se observan principalmente desde la consola.

### Consideración técnica

La lógica local anterior de movimiento, captura y victoria fue sustituida parcialmente por una estructura cliente-servidor. A partir de esta versión, el servidor debe conservar la autoridad sobre las posiciones y las reglas de la partida.

### Próxima versión

Probar dos clientes conectados al mismo servidor y crear una representación visual sencilla para los jugadores remotos.

---

## Versión 5 - Descubrimiento UDP y conexión de dos clientes

**Estado:** Completada para prueba local con dos clientes  
**Commit:** `feat: implementar descubrimiento UDP y conexión de dos clientes`

### Cambios realizados

- Se agregó descubrimiento automático de servidores mediante UDP.
- Se configuró el puerto fijo `8888` para el descubrimiento.
- Se implementaron los mensajes `discover` y `server_info`.
- Se creó el script `scripts/network/server_discovery.gd`.
- El cliente muestra en consola los servidores encontrados.
- Se mantuvo la conexión manual por IP como respaldo.
- Se configuró el inicio del countdown al conectarse dos jugadores.
- Se probaron dos clientes simultáneos conectados al mismo servidor.
- La comunicación de la partida continúa funcionando mediante TCP.

### Prueba realizada

La prueba se realizó en una sola computadora:

1. Se ejecutó el servidor.
2. El servidor inició TCP en el puerto `8889` y UDP en el puerto `8888`.
3. El primer cliente encontró el servidor por broadcast UDP.
4. Se abrió un segundo cliente desde otra instancia de Godot.
5. Ambos clientes se conectaron al mismo servidor.
6. Al conectarse el segundo jugador, inició el countdown.
7. Ambos clientes recibieron el inicio de partida.

La evidencia de esta prueba se guardó en:

`tests/evidence/prueba_dos_conexiones.png`

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para implementar el descubrimiento UDP, la conexión automática al servidor encontrado y la prueba con dos clientes.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_implementacion_two_players.png`

### Resultado

Se comprobó el descubrimiento automático mediante UDP y la conexión simultánea de dos clientes al mismo servidor.

### Limitaciones actuales

- Todavía no existe una interfaz gráfica para elegir servidor.
- La selección del servidor se realiza mediante consola.
- Los jugadores remotos todavía no se muestran visualmente dentro del escenario 3D.
- La prueba se realizó con dos clientes, aunque el servidor conserva el límite de hasta 100 conexiones.

### Próxima versión

Crear la representación visual de los jugadores remotos y actualizar sus posiciones con los mensajes `state`.
