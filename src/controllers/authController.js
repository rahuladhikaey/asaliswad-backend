import jwt from 'jsonwebtoken';
import { supabaseA, supabaseB } from '../lib/supabase.js';
import { config } from '../config/index.js';
import { HTTP_STATUS, ROLES } from '../constants/index.js';

const generateTokens = (payload) => {
  const accessToken = jwt.sign(payload, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
  const refreshToken = jwt.sign(payload, config.jwt.refreshSecret, { expiresIn: config.jwt.refreshExpiresIn });
  return { accessToken, refreshToken };
};

export const login = async (req, res, next) => {
  try {
    const { email, password, role = ROLES.CUSTOMER } = req.body;
    if (!email || !password) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, error: 'Email and password are required' });
    }

    // Route Seller Auth to Supabase B, Customer & Admin Auth to Supabase A
    const targetSupabase = role === ROLES.SELLER ? supabaseB : supabaseA;

    const { data, error } = await targetSupabase.auth.signInWithPassword({ email, password });
    if (error || !data.user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({ success: false, error: error?.message || 'Invalid credentials' });
    }

    const tokenPayload = {
      id: data.user.id,
      email: data.user.email,
      role: data.user.user_metadata?.role || role
    };

    const tokens = generateTokens(tokenPayload);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      user: data.user,
      ...tokens
    });
  } catch (err) {
    next(err);
  }
};

export const register = async (req, res, next) => {
  try {
    const { email, password, fullName, phone, role = ROLES.CUSTOMER } = req.body;
    if (!email || !password) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, error: 'Email and password are required' });
    }

    // Route Seller Registration to Supabase B, Customer Registration to Supabase A
    const targetSupabase = role === ROLES.SELLER ? supabaseB : supabaseA;

    const { data, error } = await targetSupabase.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: fullName, phone, role }
      }
    });

    if (error || !data.user) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, error: error?.message || 'Registration failed' });
    }

    const tokenPayload = {
      id: data.user.id,
      email: data.user.email,
      role
    };

    const tokens = generateTokens(tokenPayload);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      user: data.user,
      ...tokens
    });
  } catch (err) {
    next(err);
  }
};

export const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({ success: false, error: 'Refresh token required' });
    }

    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret);
    const tokenPayload = { id: decoded.id, email: decoded.email, role: decoded.role };
    const tokens = generateTokens(tokenPayload);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      ...tokens
    });
  } catch (err) {
    return res.status(HTTP_STATUS.UNAUTHORIZED).json({ success: false, error: 'Invalid refresh token' });
  }
};

export const getProfile = async (req, res, next) => {
  try {
    const targetSupabase = req.user.role === ROLES.SELLER ? supabaseB : supabaseA;
    const { data: user, error } = await targetSupabase.auth.admin.getUserById(req.user.id);
    if (error || !user) {
      return res.status(HTTP_STATUS.NOT_FOUND).json({ success: false, error: 'User not found' });
    }

    res.status(HTTP_STATUS.OK).json({ success: true, user });
  } catch (err) {
    next(err);
  }
};
