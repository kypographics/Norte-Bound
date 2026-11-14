import { Router } from 'express';
import { env } from '../config/env.mjs';
import { pingDatabase } from '../config/db.mjs';

const router = Router();

router.get('/health', async (req, res) => {
  const uptimeSeconds = Math.round(process.uptime());
  const payload = {
    status: 'ok',
    service: 'norte-bound-backend',
    environment: env.NODE_ENV,
    timestamp: new Date().toISOString(),
    uptime: {
      seconds: uptimeSeconds,
      human: `${Math.floor(uptimeSeconds / 3600)}h ${Math.floor((uptimeSeconds % 3600) / 60)}m ${uptimeSeconds % 60}s`,
    },
    database: {
      status: 'connected',
    },
  };

  try {
    await pingDatabase();
    return res.status(200).json(payload);
  } catch (error) {
    payload.status = 'degraded';
    payload.database = {
      status: 'disconnected',
      message: env.NODE_ENV === 'production' ? 'Database unavailable.' : error.message,
    };

    return res.status(503).json(payload);
  }
});

export default router;
