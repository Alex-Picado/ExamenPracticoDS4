# Evidencias de funcionamiento

Capturas de las pruebas del sistema de gestión de turnos.

| Archivo | Comprobación |
|---|---|
| `pruebas_flutter.png` | Las tres pruebas de Flutter terminan correctamente. |
| `compilacion_web.png` | Generación de la compilación Flutter Web. |
| `sincronizacion_registro.png` | Registro reflejado en Chrome y Edge sin recarga manual. |
| `sincronizacion_llamada.png` | Llamada del siguiente turno reflejada en ambos navegadores. |
| `validacion_formulario.png` | El formulario exige seleccionar un turno llamado. |
| `historial.png` | Ambos navegadores muestran los turnos atendidos con fecha y hora. |
| `concurrencia.png` | Dos solicitudes al mismo turno producen un éxito 200 y un conflicto 409. |
| `desconexion.png` | Ambos navegadores indican desconexión y deshabilitan las operaciones. |
| `reconexion_persistencia.png` | Recuperación de la conexión y conservación del historial después del reinicio. |
| `persistencia_mysql.png` | Registro del turno 8 conservado en MySQL con sus estados y fechas. |
| `rest_post.png` | POST crea un turno pendiente y responde 201. |
| `rest_patch.png` | PATCH cambia el mismo turno a llamado y después a atendido; ambas respuestas son 200. |
| `rest_get.png` | GET responde 200 y devuelve la lista de turnos. |

Para comprobar la persistencia, se compara el turno 8 en `historial.png`, antes del reinicio, con `reconexion_persistencia.png`, después del reinicio. Su identificador y fecha de atención se conservan. La consulta de `persistencia_mysql.png` muestra el registro almacenado.

Durante las pruebas de sincronización y reconexión se mantuvieron abiertos Chrome y Edge y se observaron los cambios sin presionar F5.