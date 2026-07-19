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