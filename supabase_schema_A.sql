-- =============================================================
-- ASALISWAD MARKETPLACE - SUPABASE INSTANCE A SCHEMA & RLS POLICIES
-- Scope: Users & Customer Database (Storefront, Customer Auth, Catalog, Orders, User Addresses, Payments, Reviews)
-- Target Supabase Instance A: https://bprkenwmheakcqryjupi.supabase.co
-- =============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Products Table
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

-- 3. Orders Table
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

-- 4. Store Settings Table
CREATE TABLE IF NOT EXISTS public.store_settings (
    id BIGSERIAL PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    value JSONB NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. AS-Card Applications Table
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

-- 6. Customer Saved Addresses Table
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

-- 7. Stock Notify Requests Table
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
-- ROW LEVEL SECURITY (RLS) POLICIES - INSTANCE A (USERS DB)
-- =============================================================

-- Enable RLS on all tables
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
