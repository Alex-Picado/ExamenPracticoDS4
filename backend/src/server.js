const express = require('express');
const pool = require('./db');
const http = require('node:http');
const { WebSocketServer, WebSocket } = require('ws');
const cors = require('cors');

const app = express();
app.use(cors({
  origin: [
    'http://localhost:5173',
    'http://127.0.0.1:5173',
  ],
}));
app.use(express.json());

const server = http.createServer(app);

const wss = new WebSocketServer({
  server,
  path: '/ws',
  maxPayload: 4096,
});

function enviarEvento(cliente, evento) {
  if (cliente.readyState !== WebSocket.OPEN) {
    return;
  }

  try {
    cliente.send(JSON.stringify(evento), (error) => {
      if (error) {
        cliente.terminate();
      }
    });
  } catch {
    cliente.terminate();
  }
}

function notificarCambios() {
  for (const cliente of wss.clients) {
    enviarEvento(cliente, { tipo: 'turnos_actualizados' });
  }
}

wss.on('connection', (cliente) => {
  cliente.on('error', (error) => {
    console.error('Error de WebSocket:', error.message);
  });

  enviarEvento(cliente, { tipo: 'conectado' });

  cliente.on('message', (datos) => {
    try {
      const evento = JSON.parse(datos.toString());

      if (evento?.tipo === 'sincronizar') {
        enviarEvento(cliente, { tipo: 'turnos_actualizados' });
      }
    } catch {
      enviarEvento(cliente, {
        tipo: 'error',
        mensaje: 'El mensaje debe ser JSON válido',
      });
    }
  });
});

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
    notificarCambios();
    res.status(201).json(turnos[0]);
  } catch (error) {
    console.error('Error al crear turno:', error.code);

    res.status(500).json({
      mensaje: 'No se pudo crear el turno',
    });
  }
});

app.patch('/api/turnos/:id', async (req, res) => {
  const id = Number(req.params.id);
  const estado = req.body?.estado;

  if (!Number.isSafeInteger(id) || id < 1) {
    return res.status(400).json({
      mensaje: 'El id debe ser un entero positivo',
    });
  }

  if (!['llamado', 'atendido'].includes(estado)) {
    return res.status(400).json({
      mensaje: 'El estado debe ser llamado o atendido',
    });
  }

  const sql = estado === 'llamado'
    ? `UPDATE turnos
       SET estado = 'llamado', fecha_llamado = CURRENT_TIMESTAMP
       WHERE id = ? AND estado = 'pendiente'`
    : `UPDATE turnos
       SET estado = 'atendido', fecha_atencion = CURRENT_TIMESTAMP
       WHERE id = ? AND estado = 'llamado'`;

  try {
    const [resultado] = await pool.execute(sql, [id]);

    if (resultado.affectedRows === 0) {
      const [existentes] = await pool.execute(
        'SELECT id FROM turnos WHERE id = ?',
        [id]
      );

      if (existentes.length === 0) {
        return res.status(404).json({
          mensaje: 'El turno no existe',
        });
      }

      return res.status(409).json({
        mensaje: 'El turno ya cambió de estado o la transición no está permitida',
      });
    }
    notificarCambios();

    res.json({
      mensaje: 'Estado actualizado',
      id,
      estado,
    });
  } catch (error) {
    console.error('Error al actualizar turno:', error.code);

    res.status(500).json({
      mensaje: 'No se pudo actualizar el turno',
    });
  }
});

app.post('/api/turnos/siguiente', async (req, res) => {
  let conexion;

  try {
    conexion = await pool.getConnection();
    await conexion.beginTransaction();

    const [pendientes] = await conexion.execute(
      `SELECT id
       FROM turnos
       WHERE estado = 'pendiente'
       ORDER BY id
       LIMIT 1
       FOR UPDATE`
    );

    if (pendientes.length === 0) {
      await conexion.rollback();

      return res.status(404).json({
        mensaje: 'No hay turnos pendientes',
      });
    }

    const id = pendientes[0].id;

    await conexion.execute(
      `UPDATE turnos
       SET estado = 'llamado',
           fecha_llamado = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [id]
    );

    const [turnos] = await conexion.execute(
      'SELECT * FROM turnos WHERE id = ?',
      [id]
    );

    await conexion.commit();

    notificarCambios();

    res.json(turnos[0]);
  } catch (error) {
    if (conexion) {
      try {
        await conexion.rollback();
      } catch {
        conexion.destroy();
        conexion = undefined;
      }
    }

    console.error('Error al llamar al siguiente:', error.code);

    res.status(500).json({
      mensaje: 'No se pudo llamar al siguiente turno',
    });
  } finally {
    if (conexion) {
      conexion.release();
    }
  }
});

server.listen(3000, '127.0.0.1', () => {
  console.log('API: http://localhost:3000');
  console.log('WebSocket: ws://localhost:3000/ws');
});