# Registro de prompts utilizados con inteligencia artificial (ChatGPT, GPT-5.6 Sol, Nivel de Inteligencia Media)

## Versión 3 — Jugador y funcionamiento local

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