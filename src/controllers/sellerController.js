import { supabaseB } from '../lib/supabase.js';
import { HTTP_STATUS } from '../constants/index.js';

export const registerSeller = async (req, res, next) => {
  try {
    const { storeName, gstin, phone, address, pickupLocations } = req.body;
    const sellerPayload = {
      user_id: req.user.id,
      store_name: storeName,
      gstin,
      phone,
      address,
      status: 'PENDING'
    };

    const { data: seller, error } = await supabaseB.from('sellers').insert([sellerPayload]).select();
    if (error) throw error;

    if (pickupLocations?.length > 0) {
      const locations = pickupLocations.map(loc => ({ ...loc, seller_id: seller[0].id }));
      await supabaseB.from('seller_pickup_locations').insert(locations);
    }

    res.status(HTTP_STATUS.CREATED).json({ success: true, data: seller[0] });
  } catch (err) {
    next(err);
  }
};

export const getPickupLocations = async (req, res, next) => {
  try {
    const { sellerId } = req.params;
    const { data, error } = await supabaseB.from('seller_pickup_locations').select('*').eq('seller_id', sellerId);
    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

export const createSupportTicket = async (req, res, next) => {
  try {
    const ticketPayload = req.body;
    const { data, error } = await supabaseB.from('seller_support_tickets').insert([ticketPayload]).select();
    if (error) throw error;

    res.status(HTTP_STATUS.CREATED).json({ success: true, data: data[0] });
  } catch (err) {
    next(err);
  }
};

export const updateSellerInventory = async (req, res, next) => {
  try {
    const { sellerId, productId, stockCount, imageUrl } = req.body;
    const inventoryPayload = {
      seller_id: sellerId,
      product_id: productId,
      stock_count: stockCount,
      image_url: imageUrl,
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabaseB
      .from('inventory')
      .upsert([inventoryPayload])
      .select();

    if (error) throw error;

    res.status(HTTP_STATUS.OK).json({ success: true, data: data[0] });
  } catch (err) {
    next(err);
  }
};
