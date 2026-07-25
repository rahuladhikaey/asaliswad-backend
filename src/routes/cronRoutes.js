import { Router } from 'express';
import { autoCompleteDeliveredOrders } from '../jobs/index.js';
import { purgeExpiredDeletions } from '../controllers/sellerController.js';
import { HTTP_STATUS } from '../constants/index.js';

const router = Router();

/**
 * Middleware: Verify CRON_SECRET for security if set
 */
const verifyCronSecret = (req, res, next) => {
  const cronSecret = process.env.CRON_SECRET;
  if (!cronSecret) return next(); // Pass through if no CRON_SECRET set in env

  const authHeader = req.headers['authorization'] || req.headers['x-cron-secret'];
  if (authHeader !== cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({
      success: false,
      message: 'Unauthorized: Invalid or missing CRON_SECRET header.'
    });
  }
  next();
};

/**
 * POST /api/v1/cron/auto-complete-orders
 * Manually or externally trigger order auto-completion
 */
router.post('/auto-complete-orders', verifyCronSecret, async (req, res, next) => {
  try {
    await autoCompleteDeliveredOrders();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order auto-completion job executed successfully.'
    });
  } catch (err) {
    next(err);
  }
});

/**
 * POST /api/v1/cron/purge-sellers
 * Manually or externally trigger seller account purge
 */
router.post('/purge-sellers', verifyCronSecret, async (req, res, next) => {
  try {
    await purgeExpiredDeletions(req, res, next);
  } catch (err) {
    next(err);
  }
});

export default router;
