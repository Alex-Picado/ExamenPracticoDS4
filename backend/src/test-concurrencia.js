const assert = require('node:assert/strict');

const URL_TURNOS = 'http://127.0.0.1:3000/api/turnos';

/**
 * Envía una solicitud y devuelve el código HTTP junto con el JSON.
 * Limita la espera para evitar que la prueba quede bloqueada.
 */
async function solicitar(ruta, opciones = {}) {
  const respuesta = await fetch(`${URL_TURNOS}${ruta}`, {
    ...opciones,
    signal: AbortSignal.timeout(10000),
  });

  return {
    codigo: respuesta.status,
    datos: await respuesta.json(),
  };
}

/**
 * Solicita llamar un turno concreto.
 * El servidor debe comprobar que todavía esté pendiente.
 */
async function llamarTurno(id) {
  return solicitar(`/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      estado: 'llamado',
    }),
  });
}

/**
 * Comprueba que dos solicitudes concurrentes al mismo turno
 * permiten una única transición de pendiente a llamado.
 */
async function probarConcurrencia() {
  console.log('Fecha de prueba:', new Date().toISOString());

  const creacion = await solicitar('', {
    method: 'POST',
  });

  assert.equal(
    creacion.codigo,
    201,
    'No se pudo crear el turno de prueba.'
  );

  const id = creacion.datos.id;

  console.log('Turno de prueba:', id);

  // Inicia ambas solicitudes sin esperar primero a que termine una.
  const resultados = await Promise.all([
    llamarTurno(id),
    llamarTurno(id),
  ]);

  console.table(
    resultados.map((resultado, indice) => ({
      solicitud: indice + 1,
      turno: id,
      codigo: resultado.codigo,
      mensaje: resultado.datos.mensaje,
    }))
  );

  const codigos = resultados
    .map((resultado) => resultado.codigo)
    .sort((a, b) => a - b);

  assert.deepEqual(
    codigos,
    [200, 409],
    'Se esperaba exactamente un éxito y un conflicto.'
  );

  // Consulta nuevamente para comprobar el estado guardado.
  const consulta = await solicitar('');

  assert.equal(
    consulta.codigo,
    200,
    'No se pudo consultar el resultado.'
  );

  const turno = consulta.datos.find((elemento) => elemento.id === id);

  assert.ok(turno, 'El turno creado no aparece en la consulta.');
  assert.equal(turno.estado, 'llamado');
  assert.ok(turno.fecha_llamado, 'No se guardó la fecha de llamada.');

  console.table([turno]);
  console.log('PRUEBA CORRECTA: un éxito (200) y un conflicto (409).');
}

/**
 * Informa el fallo y establece un código de salida de error.
 */
function informarError(error) {
  console.error('PRUEBA FALLIDA:', error.message);
  process.exitCode = 1;
}

probarConcurrencia().catch(informarError);