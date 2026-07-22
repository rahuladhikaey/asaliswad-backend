import { Router } from 'express';
import { getStoreSettings, updateStoreSetting, getNotifyRequests } from '../controllers/adminController.js';
import { authenticateJWT, requireRole } from '../middleware/auth.js';
import { ROLES } from '../constants/index.js';

const router = Router();

router.get('/store-settings', getStoreSettings);
router.post('/store-settings', authenticateJWT, requireRole([ROLES.SUPER_ADMIN]), updateStoreSetting);
router.get('/notify-requests', authenticateJWT, requireRole([ROLES.SUPER_ADMIN]), getNotifyRequests);

export default router;
