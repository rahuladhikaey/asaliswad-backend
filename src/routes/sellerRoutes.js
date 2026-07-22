import { Router } from 'express';
import {
  registerSeller,
  getPickupLocations,
  createSupportTicket,
  updateSellerInventory
} from '../controllers/sellerController.js';
import { authenticateJWT, requireRole } from '../middleware/auth.js';
import { ROLES } from '../constants/index.js';

const router = Router();

router.post('/register', authenticateJWT, registerSeller);
router.get('/pickup-locations/:sellerId', authenticateJWT, getPickupLocations);
router.post('/support-tickets', authenticateJWT, requireRole([ROLES.SELLER]), createSupportTicket);
router.post('/inventory', authenticateJWT, requireRole([ROLES.SELLER]), updateSellerInventory);

export default router;
