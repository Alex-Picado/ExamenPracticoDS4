const pool = require('./db');

async function probarConexion() {
  try {
    const [turnos] = await pool.execute(
      'SELECT * FROM turnos ORDER BY id'
    );

    console.log('Conexión con MySQL exitosa.');
    console.table(turnos);
  } catch (error) {
    console.error(
      'No se pudo consultar MySQL:',
      error.code || error.message
    );

    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

probarConexion();