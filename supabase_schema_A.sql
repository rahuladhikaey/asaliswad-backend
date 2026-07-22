-- =============================================================
-- ASALISWAD MARKETPLACE - SUPABASE INSTANCE A SCHEMA & RLS POLICIES
-- Scope: Storefront, Customer Auth, Super Admin Auth, Catalog, Orders, Payments, Reviews
-- Target Supabase Instance A: https://bprkenwmheakcqryjupi.supabase.co
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Admin Users Table
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'SUPER_ADMIN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Admin Audit Logs Table
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    action TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    mrp NUMERIC(10, 2),
    description TEXT,
    image_url TEXT,
    images TEXT[],
    brand TEXT DEFAULT 'asaliswad',
    stock INT DEFAULT 0,
    sku TEXT,
    low_stock_limit INT DEFAULT 5,
    status TEXT DEFAULT 'IN_STOCK',
    offers TEXT[],
    packages JSONB,
    specifications JSONB,
    category_id BIGINT REFERENCES public.categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Orders Table
CREATE TABLE IF NOT EXISTS public.orders (
    id BIGSERIAL PRIMARY KEY,
    user_email TEXT NOT NULL,
    order_status TEXT DEFAULT 'PENDING',
    total_amount NUMERIC(10, 2) NOT NULL,
    items JSONB NOT NULL,
    shipping_address JSONB NOT NULL,
    payment_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Store Settings Table
CREATE TABLE IF NOT EXISTS public.store_settings (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. AS-Card Applications Table
CREATE TABLE IF NOT EXISTS public.card_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    card_type TEXT DEFAULT 'Silver',
    status TEXT DEFAULT 'PENDING',
    card_number TEXT,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    coins INT DEFAULT 0
);

-- 8. Customer Saved Addresses Table
CREATE TABLE IF NOT EXISTS public.user_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    village TEXT,
    post_office TEXT,
    pincode TEXT NOT NULL,
    address_detail TEXT NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Stock Notify Requests Table
CREATE TABLE IF NOT EXISTS public.notify_requests (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES public.products(id) ON DELETE CASCADE,
    user_email TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_email ON public.orders(user_email);
CREATE INDEX IF NOT EXISTS idx_user_addresses_email ON public.user_addresses(user_email);

-- =============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - INSTANCE A
-- =============================================================

-- Enable RLS on all tables
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notify_requests ENABLE ROW LEVEL SECURITY;

-- Products & Categories: Public Read, Service Role / Admin Write
CREATE POLICY "Public Products Read" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admin Products Write" ON public.products FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' IN ('SUPER_ADMIN', 'ADMIN'));

CREATE POLICY "Public Categories Read" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Admin Categories Write" ON public.categories FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' IN ('SUPER_ADMIN', 'ADMIN'));

-- Orders: Users Read Own Orders, Service Role Full Access
CREATE POLICY "Customer Orders Read Own" ON public.orders FOR SELECT USING (auth.role() = 'service_role' OR auth.jwt() ->> 'email' = user_email);
CREATE POLICY "Service Role Orders Write" ON public.orders FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'role' IN ('SUPER_ADMIN', 'ADMIN'));

-- User Addresses: Customer Own Addresses Read/Write
CREATE POLICY "Customer Addresses Own Access" ON public.user_addresses FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'email' = user_email);

-- Card Applications: Customer Insert/Read Own, Admin Manage
CREATE POLICY "Customer Card Applications Access" ON public.card_applications FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'email' = user_email OR auth.jwt() ->> 'role' IN ('SUPER_ADMIN', 'ADMIN'));

-- Store Settings & Stock Alerts: Public Read, Service Role Write
CREATE POLICY "Public Settings Read" ON public.store_settings FOR SELECT USING (true);
CREATE POLICY "Service Role Settings Write" ON public.store_settings FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Notify Requests Write" ON public.notify_requests FOR ALL USING (auth.role() = 'service_role' OR auth.jwt() ->> 'email' = user_email);

-- Admin Tables: Service Role / Super Admin Only
CREATE POLICY "Admin Users Protection" ON public.admin_users FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Admin Audit Logs Protection" ON public.admin_audit_logs FOR ALL USING (auth.role() = 'service_role');

-- 6. Sellers Table (Instance A Dual Sync)
CREATE TABLE IF NOT EXISTS public.sellers (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    business_name TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    mobile_number TEXT NOT NULL,
    email TEXT NOT NULL,
    pickup_address TEXT,
    warehouse_address TEXT,
    city TEXT,
    state TEXT,
    pincode TEXT,
    status TEXT DEFAULT 'pending',
    rejection_reason TEXT,
    upi_id TEXT,
    phonepe_number TEXT,
    gstin TEXT,
    pan TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Seller Pickup Locations Table
CREATE TABLE IF NOT EXISTS public.seller_pickup_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address_line1 TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pincode TEXT NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Seller Settlements Table
CREATE TABLE IF NOT EXISTS public.seller_settlements (
    id TEXT PRIMARY KEY,
    seller_id TEXT NOT NULL,
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

-- Indexes for Query Performance
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_email ON public.orders(user_email);
CREATE INDEX IF NOT EXISTS idx_sellers_status ON public.sellers(status);
CREATE INDEX IF NOT EXISTS idx_settlements_seller ON public.seller_settlements(seller_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON public.seller_settlements(status);

-- Enable RLS on Sellers & Settlements
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_pickup_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_settlements ENABLE ROW LEVEL SECURITY;

-- Sellers RLS Policies
DROP POLICY IF EXISTS "Public Read Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Public Insert Sellers" ON public.sellers;
DROP POLICY IF EXISTS "Public Update Sellers" ON public.sellers;

CREATE POLICY "Public Read Sellers" ON public.sellers FOR SELECT USING (true);
CREATE POLICY "Public Insert Sellers" ON public.sellers FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Sellers" ON public.sellers FOR UPDATE USING (true);

-- Seller Locations RLS Policies
DROP POLICY IF EXISTS "Public Read Seller Locations" ON public.seller_pickup_locations;
DROP POLICY IF EXISTS "Public Insert Seller Locations" ON public.seller_pickup_locations;

CREATE POLICY "Public Read Seller Locations" ON public.seller_pickup_locations FOR SELECT USING (true);
CREATE POLICY "Public Insert Seller Locations" ON public.seller_pickup_locations FOR INSERT WITH CHECK (true);

-- Seller Settlements RLS Policies
DROP POLICY IF EXISTS "Public Read Settlements" ON public.seller_settlements;
DROP POLICY IF EXISTS "Public Insert Settlements" ON public.seller_settlements;
DROP POLICY IF EXISTS "Public Update Settlements" ON public.seller_settlements;

CREATE POLICY "Public Read Settlements" ON public.seller_settlements FOR SELECT USING (true);
CREATE POLICY "Public Insert Settlements" ON public.seller_settlements FOR INSERT WITH CHECK (true);
CREATE POLICY "Public Update Settlements" ON public.seller_settlements FOR UPDATE USING (true);

-- Storage Bucket & Policies
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    5242880, -- 5 MB Limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Storage Objects Read" ON storage.objects;
DROP POLICY IF EXISTS "Admin Storage Objects Insert" ON storage.objects;
DROP POLICY IF EXISTS "Admin Storage Objects Delete" ON storage.objects;

CREATE POLICY "Public Storage Objects Read" ON storage.objects FOR SELECT USING (bucket_id = 'product-images');
CREATE POLICY "Admin Storage Objects Insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'product-images');
CREATE POLICY "Admin Storage Objects Delete" ON storage.objects FOR DELETE USING (bucket_id = 'product-images');


