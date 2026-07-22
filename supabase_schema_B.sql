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
    user_id UUID NOT NULL,
    store_name TEXT NOT NULL,
    business_name TEXT,
    owner_name TEXT,
    mobile_number TEXT,
    email TEXT,
    gstin TEXT,
    pan TEXT,
    phone TEXT,
    address JSONB,
    upi_id TEXT,
    phonepe_number TEXT,
    status TEXT DEFAULT 'PENDING',
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Seller Pickup Locations Table (Shiprocket)
CREATE TABLE IF NOT EXISTS public.seller_pickup_locations (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    location_name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_inventory_seller ON public.inventory(seller_id);
CREATE INDEX IF NOT EXISTS idx_pickup_locations_seller ON public.seller_pickup_locations(seller_id);
CREATE INDEX IF NOT EXISTS idx_settlements_seller ON public.seller_settlements(seller_id);

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

-- Super Admin Tables: Service Role Protection
CREATE POLICY "Admin Users Protection" ON public.admin_users FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin Audit Logs Protection" ON public.admin_audit_logs FOR ALL USING (auth.role() = 'service_role');

-- Sellers: Sellers Read & Update Own Profile, Service Role Full Access
CREATE POLICY "Sellers Profile Access" ON public.sellers FOR ALL USING (auth.role() = 'service_role' OR auth.uid() = user_id);

-- Pickup Locations: Seller Own Locations Access
CREATE POLICY "Seller Pickup Locations Access" ON public.seller_pickup_locations FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Inventory: Seller Own Inventory Access
CREATE POLICY "Seller Inventory Access" ON public.inventory FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Stock History: Service Role / Admin Write, Seller Read Own
CREATE POLICY "Stock History Read Access" ON public.stock_history FOR SELECT USING (true);
CREATE POLICY "Stock History Service Write" ON public.stock_history FOR ALL USING (auth.role() = 'service_role');

-- Seller Settlements: Seller & Admin Access
CREATE POLICY "Seller Settlements Access" ON public.seller_settlements FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Seller Reports & Notifications: Seller Own Access
CREATE POLICY "Seller Reports Access" ON public.seller_reports FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

CREATE POLICY "Seller Notifications Access" ON public.seller_notifications FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);
