# Sistema de gestión de turnos

Examen práctico de Desarrollo IV. Aplicación Flutter Web que permite registrar, llamar y atender turnos, sincronizando los cambios entre navegadores sin recargar la página.

## Arquitectura

| Componente | Tecnología | Responsabilidad |
|---|---|---|
| Frontend | Flutter Web y Dart | Interfaz, formulario de atención, validaciones y estados de carga y conexión. |
| Backend | Node.js y Express | API REST, validaciones y reglas de cambio de estado. |
| Tiempo real | `ws` y `web_socket_channel` | Comunicación WebSocket entre el servidor y los navegadores. |
| Persistencia | MySQL con InnoDB | Almacenamiento de turnos, estados y fechas. |

Flutter se comunica con el backend mediante HTTP y WebSockets. Solamente el backend accede a MySQL.

En Flutter se separan modelos, servicios, pantalla y widgets. El backend concentra las rutas HTTP y WebSockets en `server.js`, y la conexión a MySQL en `db.js`.

## Requisitos

- Flutter compatible con el requisito de Dart declarado en `pubspec.yaml`: `^3.13.0`.
- Node.js 24 y npm.
- MySQL Server funcionando.
- MySQL Workbench para ejecutar el archivo SQL.
- Chrome y Edge para comprobar la sincronización.

Workbench es la herramienta de administración; MySQL Server es el servicio que almacena los datos.

## Instalación

### 1. Preparar MySQL

Abrir `bd.sql` en MySQL Workbench y ejecutarlo. El archivo crea la base `gestion_turnos` y su tabla `turnos`.

El identificador autoincremental representa el número de turno. Es único, aunque puede haber saltos en la numeración.

### 2. Preparar el backend

Desde la raíz del proyecto:

```powershell
cd backend
npm ci
```

En una instalación nueva, crear la configuración local:

```powershell
copy .env.example .env
```

Si `.env` ya existe, conservarlo. Completar sus valores con la conexión local de MySQL, incluida la contraseña correspondiente.

Las credenciales permanecen en `.env`, que está excluido de Git.

Comprobar la conexión e iniciar el servidor:

```powershell
npm run test:db
npm start
```

El backend utiliza `http://127.0.0.1:3000` y el canal WebSocket utiliza `ws://127.0.0.1:3000/ws`.

### 3. Iniciar Flutter Web

En otra terminal, desde la raíz del proyecto:

```powershell
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 5173
```

Abrir `http://localhost:5173` en Chrome y Edge.

El puerto 5173 coincide con los orígenes permitidos por el backend. Las direcciones utilizadas por Flutter están en `lib/config/api_config.dart`.

## Funcionamiento

1. Registrar un turno genera su número y estado `pendiente`.
2. **Llamar siguiente** selecciona el pendiente con menor identificador y lo cambia a `llamado`.
3. **Atender turno** abre un formulario que exige seleccionar un turno llamado.
4. Al confirmar, pasa a `atendido` y permanece en el historial con fecha y hora.
5. Las pestañas muestran pendientes, llamados y atendidos.
6. Los botones muestran las operaciones en proceso y se deshabilitan al perder la conexión WebSocket.

Las transiciones permitidas son:

```text
pendiente → llamado → atendido
```

Los estados y las fechas se asignan en el servidor.

## API REST

| Método | Ruta | Resultado |
|---|---|---|
| GET | `/api/turnos` | Lista ordenada por identificador. |
| POST | `/api/turnos` | Crea un turno sin requerir cuerpo; responde 201 con el turno. |
| POST | `/api/turnos/siguiente` | Llama al primer pendiente y devuelve el turno; responde 404 si no hay pendientes. |
| PATCH | `/api/turnos/:id` | Cambia el estado de un turno concreto. |

El cuerpo de PATCH utiliza JSON:

```json
{"estado":"llamado"}
```

Para completar la atención:

```json
{"estado":"atendido"}
```

PATCH responde con `mensaje`, `id` y `estado`. Sus errores controlados utilizan un JSON con `mensaje`: 400 para identificador o estado inválido, 404 para turno inexistente y 409 para una transición incompatible. Los fallos de acceso a datos responden 500.

Cada turno contiene `id`, `estado`, `fecha_creacion`, `fecha_llamado` y `fecha_atencion`. Las fechas de llamada y atención son `null` hasta realizar esas operaciones.

## HTTP y WebSockets

HTTP se utiliza para consultar o modificar los turnos y recibir el resultado de cada solicitud.

WebSocket mantiene un canal que permite enviar mensajes en ambas direcciones. Flutter utiliza `web_socket_channel` para enviar y escuchar esos mensajes. [Documentación oficial de Flutter](https://docs.flutter.dev/cookbook/networking/web-sockets).

En este proyecto, WebSocket avisa de los cambios y Flutter consulta entonces el estado actualizado mediante GET. No se realizan consultas HTTP periódicas.

### Eventos y sincronización

| Dirección | Mensaje | Propósito |
|---|---|---|
| Servidor → Flutter | `{"tipo":"conectado"}` | Notificar la apertura del canal. |
| Flutter → servidor | `{"tipo":"sincronizar"}` | Solicitar una notificación de sincronización. |
| Servidor → Flutter | `{"tipo":"turnos_actualizados"}` | Indicar que debe consultarse la lista actual. |

Después de guardar un cambio, el backend envía `turnos_actualizados` a los clientes conectados. Cada pantalla realiza GET y actualiza sus pestañas sin F5.

### Desconexión y recuperación

Al detectar el cierre o un error del canal, Flutter muestra la desconexión, deshabilita las operaciones y programa un reintento después de dos segundos.

Al recuperar el canal, envía `sincronizar`. La respuesta provoca una nueva consulta para recuperar los cambios ocurridos durante la desconexión.

La pantalla libera la conexión anterior y evita crear suscripciones o temporizadores duplicados. Las operaciones de registro y cambio de estado no se repiten automáticamente.

## Control de concurrencia

Para llamar al siguiente, el backend utiliza una transacción y selecciona el primer pendiente con `SELECT ... FOR UPDATE`. La misma conexión realiza la selección, actualización y confirmación. Si ocurre un error, revierte la transacción. [Lecturas con bloqueo en MySQL](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html).

Para cambiar un turno concreto, PATCH ejecuta un UPDATE condicionado por el estado anterior y comprueba las filas afectadas. InnoDB aplica los bloqueos correspondientes a la actualización. [Bloqueos de las sentencias en InnoDB](https://dev.mysql.com/doc/refman/8.4/en/innodb-locks-set.html).

Si dos solicitudes intentan llamar al mismo identificador, solamente una realiza la transición: obtiene 200 y la otra recibe 409.

Dos solicitudes a **Llamar siguiente** pueden atenderse correctamente con identificadores diferentes cuando existen varios pendientes.

## Pruebas

Con el backend encendido, ejecutar desde la raíz:

```powershell
npm --prefix backend run test:db
npm --prefix backend run test:concurrencia
flutter analyze
flutter test
flutter build web
```

La prueba de concurrencia crea un turno, envía dos PATCH concurrentes al mismo identificador y exige obtener exactamente un 200 y un 409. También consulta el estado final y comprueba que tenga fecha de llamada. El turno de prueba permanece guardado.

Para observar los mensajes WebSocket:

```powershell
npm --prefix backend run test:ws
```

Esta comprobación permanece escuchando hasta detenerla con Ctrl+C.

## Evidencias y demostración

Las capturas se guardan en `evidencia/`.

La comprobación final debe mostrar:

- Registro, llamada y atención reflejados en Chrome y Edge sin F5.
- Validación del formulario de atención.
- Respuestas de la API REST.
- Rechazo de la segunda llamada concurrente al mismo turno.
- Conservación de los registros después de reiniciar el backend.
- Desconexión y recuperación automática en ambos navegadores.
- Análisis, pruebas y compilación de Flutter Web.

## Dependencias

Las dependencias del backend están declaradas en `backend/package.json` y fijadas en `backend/package-lock.json`.

Las dependencias de Flutter están declaradas en `pubspec.yaml` y fijadas en `pubspec.lock`.

## Fuentes

- [Node.js: entorno de ejecución de JavaScript](https://nodejs.org/en/about).
- [Flutter: comunicación con WebSockets](https://docs.flutter.dev/cookbook/networking/web-sockets).
- [MySQL: lecturas con bloqueo](https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html).
- [MySQL: bloqueos de las sentencias en InnoDB](https://dev.mysql.com/doc/refman/8.4/en/innodb-locks-set.html).