/**
 * Comprueba manualmente la conexión y los eventos WebSocket.
 * Envía una solicitud de sincronización al conectar.
 * Permanece escuchando hasta detenerlo con Ctrl+C.
 */
const WebSocket = require('ws');

const socket = new WebSocket('ws://localhost:3000/ws');

socket.on('open', () => {
  console.log('Conexión WebSocket abierta');
  socket.send(JSON.stringify({ tipo: 'sincronizar' }));
});

socket.on('message', (datos) => {
  console.log('Evento recibido:', datos.toString());
});

socket.on('close', () => {
  console.log('Conexión WebSocket cerrada');
});

socket.on('error', (error) => {
  console.error('Error:', error.message);
});