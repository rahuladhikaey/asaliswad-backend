import { supabaseA } from '../lib/supabase.js';
import { HTTP_STATUS } from '../constants/index.js';

export const getStoreSettings = async (req, res, next) => {
  try {
    const { key } = req.query;
    let query = supabaseA.from('store_settings').select('*');
    if (key) {
      query = query.eq('key', key).single();
    }

    const { data, error } = await query;
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

export const updateStoreSetting = async (req, res, next) => {
  try {
    const { key, value } = req.body;
    const { data, error } = await supabaseA.from('store_settings').upsert({ key, value }).select();
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data: data[0] });
  } catch (err) {
    next(err);
  }
};

export const getNotifyRequests = async (req, res, next) => {
  try {
    const { data, error } = await supabaseA.from('notify_requests').select('*').order('created_at', { ascending: false });
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data });
  } catch (err) {
    next(err);
  }
};
