const express = require('express');
const pool = require('./db');

const app = express();
app.use(express.json());

app.get('/api/turnos', async (req, res) => {
  try {
    const [turnos] = await pool.execute(
      'SELECT * FROM turnos ORDER BY id'
    );

    res.json(turnos);
  } catch (error) {
    console.error('Error al consultar turnos:', error.code);
    res.status(500).json({
      mensaje: 'No se pudieron consultar los turnos',
    });
  }
});

app.post('/api/turnos', async (req, res) => {
  try {
    const [resultado] = await pool.execute(
      'INSERT INTO turnos (estado) VALUES (?)',
      ['pendiente']
    );

    const [turnos] = await pool.execute(
      'SELECT * FROM turnos WHERE id = ?',
      [resultado.insertId]
    );

    res.status(201).json(turnos[0]);
  } catch (error) {
    console.error('Error al crear turno:', error.code);

    res.status(500).json({
      mensaje: 'No se pudo crear el turno',
    });
  }
});

app.listen(3000, '127.0.0.1', () => {
  console.log('Servidor disponible en http://localhost:3000');
});