import { Router } from 'express';
import { getOrders, createOrder, updateOrderStatus, deleteOrder } from '../controllers/orderController.js';
import { authenticateJWT, requireRole } from '../middleware/auth.js';
import { ROLES } from '../constants/index.js';

const router = Router();

router.get('/', authenticateJWT, getOrders);
router.post('/', createOrder);
router.put('/:id', authenticateJWT, updateOrderStatus);
router.delete('/:id', authenticateJWT, requireRole([ROLES.SUPER_ADMIN]), deleteOrder);

export default router;
