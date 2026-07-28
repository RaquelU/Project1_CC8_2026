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

## Versión 6 - Adaptación al protocolo actualizado y prueba mediante VPN

**Estado:** Completada para prueba remota entre dos computadoras  
**Commit:** `feat: adaptar red y reglas al protocolo actualizado`

### Cambios de ideas

Debido a que se hizo un cambio tres dias antes de la entrega del proyecto, la version esperada con la representacion visual de los jugadores remotos fue
modificada y la version seis ahora posee los cambios del "nuevo protocolo". 

### Cambios realizados

- Se actualizó la implementación de red para cumplir con la versión vigente del protocolo.
- Se reforzó el procesamiento de mensajes JSON, el framing TCP y las validaciones de entrada.
- Se implementó el ciclo completo de la partida con regreso automático al lobby.
- Se ajustaron el spawn, la captura, el robo, la victoria y las desconexiones según las reglas oficiales.
- Se mantuvo UDP exclusivamente para descubrimiento y TCP para toda la comunicación del juego.
- Se agregaron las vías de conexión por broadcast, UDP unicast y TCP directo desde terminal.
- Se mantuvo al servidor como autoridad de posiciones, bandera y resultado de la partida.

### Prueba realizada

La prueba se realizó entre dos computadoras conectadas mediante ZeroTier:

1. El servidor se ejecutó en una computadora.
2. El segundo cliente utilizó la IP virtual del servidor.
3. El cliente envió `discover` por UDP al puerto `8888`.
4. Recibió `server_info` con el puerto TCP anunciado.
5. Se estableció la conexión TCP.
6. Ambos jugadores recibieron el countdown y pudieron participar en la partida.
7. Se comprobó el movimiento, la captura, el robo, la victoria y el inicio de una nueva ronda sin reconectarse.

La evidencia se guardó en:

`tests/evidence/prueba_vpn_cliente1.png`
`tests/evidence/prueba_vpn_cliente2.png`

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para revisar el protocolo actualizado y adaptar los scripts de red conservando una estructura clara y compatible.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_cambio_protocolo.png`

### Resultado

Se comprobó que el cliente y el servidor pueden comunicarse entre dos computadoras distintas mediante descubrimiento UDP unicast y conexión TCP, manteniendo las reglas principales del protocolo.

### Limitaciones actuales

- La selección y configuración de conexión todavía se realiza desde la terminal.
- La interfaz gráfica para descubrir y seleccionar servidores queda pendiente.

### Próxima versión

Crear una interfaz para mostrar servidores encontrados, seleccionar uno y realizar la conexión sin utilizar argumentos de terminal.

## Versión 7 - Interfaz para descubrimiento y conexión a servidores

**Estado:** Completada para prueba local con dos clientes  
**Commit:** `feat: agregar interfaz para descubrir y seleccionar servidores`

### Cambios realizados

- Se creó la escena `scenes/ui/server_browser.tscn`.
- Se creó el script `scripts/ui/server_browser.gd`.
- Se integró la interfaz dentro de `game_world.tscn` mediante un `CanvasLayer`.
- Se agregó un campo para ingresar el nombre del jugador.
- Se agregó un botón para buscar servidores mediante UDP.
- Los servidores encontrados se muestran en una lista seleccionable.
- Se agregó conexión al servidor seleccionado sin utilizar argumentos de terminal.
- Se agregó búsqueda por IP como respaldo para redes donde el broadcast no funcione.
- Se mantuvo la opción de conexión TCP directa mediante IP y puerto.
- Se modificó `server_discovery.gd` para entregar los resultados a la interfaz.
- Se modificó `game_client.gd` para permitir que la interfaz inicie la conexión.
- La interfaz se oculta después de recibir el mensaje `welcome`.

### Prueba realizada

La prueba se realizó en una computadora con el servidor y dos clientes:

1. Se ejecutó el servidor desde la terminal.
2. Se abrió el cliente sin argumentos de conexión.
3. La interfaz buscó y mostró los servidores disponibles.
4. Se seleccionó el servidor desde la lista.
5. Se realizó la conexión mediante el botón correspondiente.
6. Se abrió un segundo cliente y se repitió el proceso.
7. Al conectarse el segundo jugador, inició el countdown.
8. Se comprobó el movimiento, la captura, el robo, la victoria y el inicio de una nueva ronda.
9. La interfaz permaneció oculta durante la partida.

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para diseñar la estructura de la interfaz ya que no es uno de mis fuertes y asi conectarla con los scripts existentes de descubrimiento y cliente.
Hubieron un par de modificaciones leves pero se dejaron algunas funciones en caso de necesitarlas.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_interfaz_ui.png`

### Resultado

Se comprobó que el usuario puede buscar, seleccionar y conectarse a un servidor desde una interfaz gráfica, sin escribir argumentos de conexión en la terminal.

### Consideración sobre redes y VPN

El descubrimiento automático depende de que el broadcast UDP llegue a los demás dispositivos de la red. Por esta razón, la interfaz conserva la búsqueda manual por IP como respaldo para VPN o redes con restricciones.

### Próxima versión

Agregar manejo visual de errores de conexión y volver a mostrar el buscador cuando el servidor se desconecte.

## Versión 8 - Visualización multijugador completa y corrección del descubrimiento por VPN

**Estado:** Completada
**Commit:** `feat: agregar visualización de jugadores remotos, vista espectadora del servidor y corregir descubrimiento UDP por subred`

### Cambios realizados

- Se creó `scripts/player/remote_player.gd` y `scenes/player/remote_player.tscn` para representar visualmente a los demás jugadores conectados dentro de `game_world.tscn`, con interpolación suave de posición.
- Se modificó `game_client.gd` para que, además de aplicar la posición del jugador local, cree, mueva y elimine las cápsulas de los jugadores remotos según aparecen o desaparecen del arreglo `players[]` recibido en cada mensaje `state`.
- Se corrigió un error en la posición visual de la bandera portada: antes solo se reparentaba al jugador local, por lo que en cualquier jugador remoto la bandera se quedaba pegada al suelo, escondida en el centro de su modelo. Ahora se reparenta correctamente a cualquier portador (local o remoto), con un desplazamiento elevado para que sea claramente visible.
- Se agregó una etiqueta `Label3D` con el nombre de cada jugador remoto, capturando los nombres desde el mensaje `lobby` (el único que incluye `id` y `name` juntos, ya que `state` solo transmite posición).
- Se creó `scenes/network/server_player_view.tscn` y se extendió `game_server.gd` para que el servidor deje de ser una consola vacía y muestre visualmente el mapa, el círculo central, la bandera y a todos los jugadores conectados en tiempo real, leyendo directamente los diccionarios internos `players` y `flag` (sin pasar por red, al tratarse del mismo proceso). Se agregó una cámara cenital fija y un HUD simple con la fase de la partida, el puerto TCP y la cantidad de jugadores conectados.
- Se corrigió el tamaño de las etiquetas de nombre: `fixed_size = true` en `Label3D` mantenía el texto con el mismo tamaño en pantalla sin importar la distancia de la cámara, por lo que en la vista alejada del servidor los nombres se veían enormes y tapaban las cápsulas. Se quitó esa propiedad para que el texto escale con la distancia, como cualquier otro objeto 3D de la escena.
- Se corrigió el descubrimiento de servidores por UDP para redes VPN: antes, el broadcast dirigido a la subred (necesario para redes como ZeroTier) solo se enviaba si se indicaba manualmente `--broadcast=<ip>` por terminal. Se modificó `server_discovery.gd` para detectar automáticamente todas las direcciones IPv4 locales de la máquina (incluyendo adaptadores virtuales como el de ZeroTier) y calcular el broadcast de cada una, sin depender de un argumento manual. También se filtraron las direcciones `169.254.x.x` (link-local/APIPA de interfaces inactivas), que generaban intentos de envío fallidos sin ningún efecto real.

### Cambios de idea

Se evaluó agregar un campo opcional `"rot"` (no documentado en el catálogo del protocolo, pero permitido como campo ignorable según la sección 2.2 del estándar) para replicar en los demás clientes hacia dónde mira cada jugador. Se decidió no implementarlo: ningún otro proyecto de la clase lo contempla, y se priorizó mantener el protocolo exactamente como fue acordado en conjunto, sin extensiones unilaterales que ningún compañero pudiera aprovechar.

### Prueba realizada

Prueba entre dos computadoras mediante ZeroTier:

1. Se detectó que el descubrimiento era asimétrico: la computadora de una compañera encontraba el servidor local, pero la propia no encontraba el de ella.
2. Se determinó que la causa era la falta de broadcast automático de subred: el paquete `discover` solo salía hacia `255.255.255.255`, dirección que normalmente no cruza el adaptador virtual de la VPN.
3. Tras implementar la detección automática de subredes, se ejecutó el cliente sin ningún argumento adicional y se comprobó el descubrimiento correcto de servidores en la red local, incluyendo múltiples adaptadores virtuales (VMware/VirtualBox) presentes en la misma máquina, lo que confirmó que el servidor respondía por cada interfaz alcanzable.
4. Se observó en la consola que los intentos de envío hacia direcciones `169.254.x.x` desaparecieron tras filtrarlas, aunque no se guardó captura de este paso en particular
ya que al hacer las pruebas cerre por accidente la PowerShell.

La evidencia de que se filtraron las direcciones se encuentra en:

`tests/evidence/descubrimiento_udp_prueba.png`

### Uso de inteligencia artificial

A partir de esta versión se utilizó **Claude Sonnet 5 (Nivel de Inteligencia Media)** como apoyo de desarrollo, en lugar de ChatGPT debido a unos errores técnicos
que ya no me permitieron utilizarlo y decidí cambiar de motor para evitar versiones gratuitas.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`
`docs/prompts_ia/prompt_mejoras_proyecto.png`

### Resultado

Todos los jugadores conectados son ahora visibles entre sí dentro del cliente (incluyendo quién porta la bandera), y el servidor deja de ser una consola ciega para mostrar visualmente el estado completo de la partida, cumpliendo con el requisito del enunciado de que el modo servidor solo debe mostrar el juego de todos los jugadores. El descubrimiento por UDP funciona automáticamente sobre redes VPN como ZeroTier, sin necesidad de argumentos manuales.

### Limitaciones actuales

- La orientación de los jugadores remotos no se replica: todos se muestran con una orientación fija, ya que el protocolo acordado por la clase no contempla ese campo.
- El cálculo automático del broadcast de subred asume máscara `/24`; en redes con una máscara distinta seguiría siendo necesario el respaldo manual `--broadcast=<ip>`.

### Próxima versión

Completar la documentación final del proyecto (bitácora, prompts de IA y referencias al historial de Git) y validar la entrega completa contra el protocolo y el enunciado del proyecto.