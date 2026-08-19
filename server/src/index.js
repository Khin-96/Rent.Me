require('dotenv').config();
const app = require('./app');

const PORT = Number(process.env.PORT) || 10000;

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`[HabitatHub Server] Running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode`);
});

// Handle graceful shutdowns
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
