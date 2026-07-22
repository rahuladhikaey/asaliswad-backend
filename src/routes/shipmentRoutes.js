import { Router } from 'express';
import { createShipment } from '../controllers/shipmentController.js';
import { authenticateJWT, requireRole } from '../middleware/auth.js';
import { ROLES } from '../constants/index.js';

const router = Router();

router.post('/create-shipment', authenticateJWT, requireRole([ROLES.SUPER_ADMIN, ROLES.SELLER]), createShipment);

export default router;
