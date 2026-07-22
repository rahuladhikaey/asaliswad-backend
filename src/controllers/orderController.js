import { supabaseA } from '../lib/supabase.js';
import { HTTP_STATUS } from '../constants/index.js';

export const getOrders = async (req, res, next) => {
  try {
    const { sellerId, customerId } = req.query;
    let query = supabaseA.from('orders').select('*').order('created_at', { ascending: false });

    if (sellerId) {
      query = query.eq('seller_id', sellerId);
    }
    if (customerId) {
      query = query.eq('customer_id', customerId);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

export const createOrder = async (req, res, next) => {
  try {
    const orderData = req.body;
    const { data, error } = await supabaseA.from('orders').insert([orderData]).select();
    if (error) throw error;

    res.status(HTTP_STATUS.CREATED).json({ success: true, data: data[0] });
  } catch (err) {
    next(err);
  }
};

export const updateOrderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { order_status, payment_status, payment_method } = req.body;

    const updateFields = {};
    if (order_status) updateFields.order_status = order_status;
    if (payment_status) updateFields.payment_status = payment_status;
    if (payment_method) updateFields.payment_method = payment_method;

    const { data, error } = await supabaseA.from('orders').update(updateFields).eq('id', id).select();
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data: data[0] });
  } catch (err) {
    next(err);
  }
};

export const deleteOrder = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { error } = await supabaseA.from('orders').delete().eq('id', id);
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, message: 'Order deleted' });
  } catch (err) {
    next(err);
  }
};
