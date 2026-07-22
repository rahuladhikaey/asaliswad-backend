-- =============================================================
-- ASALISWAD MARKETPLACE - SUPABASE INSTANCE B SCHEMA & RLS POLICIES
-- Scope: Super Admin & Seller Database (Super Admin Auth, Admin Audit Logs, Seller Auth, Seller Profiles, Inventory, Pickup Locations, Settlements, Reports, Notifications)
-- Target Supabase Instance B: https://qgiichnytbukisofuqiv.supabase.co
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Super Admin Users Table
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'SUPER_ADMIN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Super Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    action TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Sellers Table
CREATE TABLE IF NOT EXISTS public.sellers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    store_name TEXT,
    business_name TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    email TEXT NOT NULL,
    gstin TEXT,
    pan TEXT,
    phone TEXT,
    address JSONB,
    pickup_address TEXT,
    warehouse_address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    upi_id TEXT,
    phonepe_number TEXT,
    status TEXT DEFAULT 'approved',
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Seller Pickup Locations Table (Shiprocket)
CREATE TABLE IF NOT EXISTS public.seller_pickup_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    location_name TEXT,
    name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    address_line1 TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Seller Inventory Table
CREATE TABLE IF NOT EXISTS public.inventory (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL,
    stock_count INT DEFAULT 0,
    reserved_count INT DEFAULT 0,
    image_url TEXT,
    cloudinary_public_id TEXT,
    width INT,
    height INT,
    format TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Stock History Audit Table
CREATE TABLE IF NOT EXISTS public.stock_history (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    change_type TEXT NOT NULL,
    quantity INT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Seller Settlements Table
CREATE TABLE IF NOT EXISTS public.seller_settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    seller_name TEXT NOT NULL,
    seller_upi_id TEXT,
    seller_phonepe TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    commission_deducted NUMERIC(10, 2) DEFAULT 0,
    status TEXT DEFAULT 'PENDING',
    payment_method TEXT DEFAULT 'UPI / PhonePe Manual Transfer',
    utr_number TEXT,
    notes TEXT,
    payment_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Seller Earnings & Reports Table
CREATE TABLE IF NOT EXISTS public.seller_reports (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. System & Merchant Notifications Table
CREATE TABLE IF NOT EXISTS public.seller_notifications (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    read_status BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_sellers_user_id ON public.sellers(user_id);
CREATE INDEX IF NOT EXISTS idx_sellers_status ON public.sellers(status);
CREATE INDEX IF NOT EXISTS idx_inventory_seller ON public.inventory(seller_id);
CREATE INDEX IF NOT EXISTS idx_pickup_locations_seller ON public.seller_pickup_locations(seller_id);
CREATE INDEX IF NOT EXISTS idx_settlements_seller ON public.seller_settlements(seller_id);

-- =============================================================
-- AUTOMATIC TRIGGER FOR NEW SELLER REGISTRATION
-- =============================================================

CREATE OR REPLACE FUNCTION public.handle_new_seller()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.raw_user_meta_data->>'role') = 'seller' OR (NEW.raw_user_meta_data->>'role') IS NULL THEN
    INSERT INTO public.sellers (
      id,
      user_id,
      business_name,
      owner_name,
      mobile_number,
      email,
      status
    )
    VALUES (
      NEW.id,
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'business_name', NEW.raw_user_meta_data->>'full_name', 'New Merchant'),
      COALESCE(NEW.raw_user_meta_data->>'full_name', 'Owner'),
      COALESCE(NEW.raw_user_meta_data->>'phone', ''),
      NEW.email,
      'approved'
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_seller ON auth.users;
CREATE TRIGGER on_auth_user_created_seller
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_seller();

-- =============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - INSTANCE B (SUPER ADMIN & SELLERS)
-- =============================================================

-- Enable RLS on all tables
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_pickup_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_notifications ENABLE ROW LEVEL SECURITY;

-- Super Admin Protection
DROP POLICY IF EXISTS "Admin Users Protection" ON public.admin_users;
CREATE POLICY "Admin Users Protection" ON public.admin_users FOR ALL USING (true);

DROP POLICY IF EXISTS "Admin Audit Logs Protection" ON public.admin_audit_logs;
CREATE POLICY "Admin Audit Logs Protection" ON public.admin_audit_logs FOR ALL USING (true);

-- Sellers: Allow Public Read, Insert (Registration), Update, Delete
DROP POLICY IF EXISTS "Public Read Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Public Insert Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Public Update Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Public Delete Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Sellers Profile Access" ON public.sellers;

CREATE POLICY "Public Read Sellers" ON public.sellers FOR SELECT USING (true);
CREATE POLICY "Public Insert Sellers" ON public.sellers FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Sellers" ON public.sellers FOR UPDATE USING (true);
CREATE POLICY "Public Delete Sellers" ON public.sellers FOR DELETE USING (true);

-- Pickup Locations: Allow Read & Write Access
DROP POLICY IF EXISTS "Public Read Seller Locations" ON public.seller_pickup_locations;
DROP POLICY IF EXISTS "Public Insert Seller Locations" ON public.seller_pickup_locations;
DROP POLICY IF EXISTS "Seller Pickup Locations Access" ON public.seller_pickup_locations;

CREATE POLICY "Public Read Seller Locations" ON public.seller_pickup_locations FOR SELECT USING (true);
CREATE POLICY "Public Insert Seller Locations" ON public.seller_pickup_locations FOR INSERT WITH CHECK (true);

-- Inventory: Allow Read & Write
DROP POLICY IF EXISTS "Seller Inventory Access" ON public.inventory;
CREATE POLICY "Seller Inventory Access" ON public.inventory FOR ALL USING (true);

-- Stock History
DROP POLICY IF EXISTS "Stock History Read Access" ON public.stock_history;
DROP POLICY IF EXISTS "Stock History Service Write" ON public.stock_history;
CREATE POLICY "Stock History Read Access" ON public.stock_history FOR SELECT USING (true);
CREATE POLICY "Stock History Service Write" ON public.stock_history FOR ALL USING (true);

-- Seller Settlements
DROP POLICY IF EXISTS "Seller Settlements Access" ON public.seller_settlements;
CREATE POLICY "Seller Settlements Access" ON public.seller_settlements FOR ALL USING (true);

-- Seller Reports & Notifications
DROP POLICY IF EXISTS "Seller Reports Access" ON public.seller_reports;
CREATE POLICY "Seller Reports Access" ON public.seller_reports FOR ALL USING (true);

DROP POLICY IF EXISTS "Seller Notifications Access" ON public.seller_notifications;
CREATE POLICY "Seller Notifications Access" ON public.seller_notifications FOR ALL USING (true);
