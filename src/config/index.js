import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: process.env.PORT || 5000,
  env: process.env.NODE_ENV || 'development',
  apiBaseUrl: process.env.API_BASE_URL || 'https://api.asaliswad.com',
  jwt: {
    secret: process.env.JWT_SECRET || 'x9#kL2!pQ8$vN5@mZ1*cJ4^yH7&tR0%bW3',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'x9#kL2!pQ8$vN5@mZ1*cJ4^yH7&tR0%bW3_refresh',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d'
  },
  // Supabase Instance A: Users & Customer Database (Storefront, Products, Categories, Orders, User Addresses, Payments)
  supabaseA: {
    url: process.env.SUPABASE_A_URL || 'https://bprkenwmheakcqryjupi.supabase.co',
    serviceKey: process.env.SUPABASE_A_SERVICE_ROLE_KEY || 'sb_publishable_W3vW-6g_CDVw57zEK-oF5A_Y3RzKCzR',
    anonKey: process.env.SUPABASE_A_ANON_KEY || 'sb_publishable_W3vW-6g_CDVw57zEK-oF5A_Y3RzKCzR'
  },
  // Supabase Instance B: Super Admin & Seller Database (Super Admin Auth, Admin Audit Logs, Seller Profiles, Inventory, Pickup Locations, Settlements, Reports, Notifications)
  supabaseB: {
    url: process.env.SUPABASE_B_URL || 'https://qgiichnytbukisofuqiv.supabase.co',
    serviceKey: process.env.SUPABASE_B_SERVICE_ROLE_KEY || 'sb_publishable_kMnEF2aqyz1z2SOB-sxtCQ_s4J-VisB',
    anonKey: process.env.SUPABASE_B_ANON_KEY || 'sb_publishable_kMnEF2aqyz1z2SOB-sxtCQ_s4J-VisB'
  },
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_ShRpqbs6hVT6Ie',
    keySecret: process.env.RAZORPAY_KEY_SECRET || '5LUjZ94LMDnjwlLyB9cUU5cb'
  },
  shiprocket: {
    email: process.env.SHIPROCKET_EMAIL || 'dummy@example.com',
    password: process.env.SHIPROCKET_PASSWORD || 'dummypassword'
  },
  brevo: {
    apiKey: process.env.BREVO_API_KEY || ''
  },
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || 'p1ish280',
    apiKey: process.env.CLOUDINARY_API_KEY || '514334232244449',
    apiSecret: process.env.CLOUDINARY_API_SECRET || '',
    uploadPreset: process.env.CLOUDINARY_UPLOAD_PRESET || 'asaliswad_products'
  }
};
