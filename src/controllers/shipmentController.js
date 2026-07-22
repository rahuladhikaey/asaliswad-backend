import axios from 'axios';
import { config } from '../config/index.js';
import { HTTP_STATUS } from '../constants/index.js';

let shiprocketToken = '';

const getShiprocketToken = async () => {
  if (shiprocketToken) return shiprocketToken;
  try {
    const res = await axios.post('https://apiv2.shiprocket.in/v1/external/auth/login', {
      email: config.shiprocket.email,
      password: config.shiprocket.password
    });
    shiprocketToken = res.data.token;
    return shiprocketToken;
  } catch (err) {
    return null;
  }
};

export const createShipment = async (req, res, next) => {
  try {
    const shipmentData = req.body;
    const token = await getShiprocketToken();

    if (!token) {
      return res.status(HTTP_STATUS.OK).json({
        success: true,
        shipmentId: `mock_shipment_${Date.now()}`,
        status: 'MANIFESTED',
        isMock: true
      });
    }

    const response = await axios.post('https://apiv2.shiprocket.in/v1/external/orders/create/adhoc', shipmentData, {
      headers: { Authorization: `Bearer ${token}` }
    });

    res.status(HTTP_STATUS.OK).json({ success: true, data: response.data });
  } catch (err) {
    next(err);
  }
};
