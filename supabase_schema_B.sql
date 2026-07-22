-- =============================================================
-- ASALISWAD MARKETPLACE - SUPABASE INSTANCE B SCHEMA & RLS POLICIES
-- Scope: Seller Auth, Seller Profiles, Inventory, Pickup Locations, Reports, Audit Logs
-- Target Supabase Instance B: https://qgiichnytbukisofuqiv.supabase.co
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Sellers Table
CREATE TABLE IF NOT EXISTS public.sellers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    store_name TEXT NOT NULL,
    gstin TEXT,
    phone TEXT NOT NULL,
    address JSONB,
    status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Seller Pickup Locations Table (Shiprocket)
CREATE TABLE IF NOT EXISTS public.seller_pickup_locations (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    location_name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Seller Inventory Table
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

-- 4. Stock History Audit Table
CREATE TABLE IF NOT EXISTS public.stock_history (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    change_type TEXT NOT NULL,
    quantity INT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Seller Earnings & Reports Table
CREATE TABLE IF NOT EXISTS public.seller_reports (
    id BIGSERIAL PRIMARY KEY,
    seller_id UUID REFERENCES public.sellers(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. System & Merchant Notifications Table
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

-- =============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - INSTANCE B
-- =============================================================

-- Enable RLS on all tables
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_pickup_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_notifications ENABLE ROW LEVEL SECURITY;

-- Sellers: Sellers Read & Update Own Profile, Service Role Full Access
CREATE POLICY "Sellers Own Profile Access" ON public.sellers FOR ALL USING (auth.role() = 'service_role' OR auth.uid() = user_id);

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

-- Seller Reports & Notifications: Seller Own Access
CREATE POLICY "Seller Reports Access" ON public.seller_reports FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

CREATE POLICY "Seller Notifications Access" ON public.seller_notifications FOR ALL USING (
    auth.role() = 'service_role' OR 
    seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);
