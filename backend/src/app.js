import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.mjs';
import { closePool } from './config/db.mjs';
import healthRoutes from './routes/health.routes.mjs';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler.mjs';

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));

app.use('/api/v1', healthRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

const server = app.listen(env.PORT, () => {
  console.log(`[norte-bound] API listening on port ${env.PORT} (${env.NODE_ENV})`);
  console.log(`[norte-bound] Health check: http://localhost:${env.PORT}/api/v1/health`);
});

async function shutdown(signal) {
  console.log(`[norte-bound] Received ${signal}. Shutting down gracefully...`);

  server.close(async () => {
    try {
      await closePool();
      process.exit(0);
    } catch (error) {
      console.error('[norte-bound] Error while closing the database pool.', error);
      process.exit(1);
    }
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));

export default app;
