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

### Cambios de idea

No hubo cambios de idea. Desde el inicio se decidió trabajar en Godot 3D con GDScript y seguir el protocolo que está siendo definido por la clase.

### Próxima versión

Crear el jugador provisional, implementar movimiento local y probar la colisión con el suelo.

## Versión 3 - Jugador y reglas locales

**Estado:** Completada  
**Commit:** pendiente

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

### Uso de inteligencia artificial

Se utilizó ChatGPT como apoyo para generar una base del script `scripts/player/player.gd`.

El prompt utilizado y las modificaciones realizadas se encuentran documentados en:

`docs/prompts_ia.md`