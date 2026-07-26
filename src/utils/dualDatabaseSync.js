import { createClient } from '@supabase/supabase-js';
import { config } from '../config/index.js';

// Database A (Master DB - Admin & Seller operations)
const dbAUrl = config.supabaseB?.url || config.supabaseA?.url || 'https://qgiichnytbukisofuqiv.supabase.co';
const dbAKey = config.supabaseB?.serviceKey || config.supabaseB?.anonKey || 'sb_publishable_kMnEF2aqyz1z2SOB-sxtCQ_s4J-VisB';

// Database B (Customer DB - Customer storefront & catalog)
const dbBUrl = process.env.SUPABASE_A_URL || 'https://bprkenwmheakcqryjupi.supabase.co';
const dbBKey = process.env.SUPABASE_A_SERVICE_ROLE_KEY || process.env.SUPABASE_A_ANON_KEY || 'sb_publishable_W3vW-6g_CDVw57zEK-oF5A_Y3RzKCzR';

export const masterDb = createClient(dbAUrl, dbAKey);
export const customerDb = createClient(dbBUrl, dbBKey);

export async function syncProductToCustomerDb(product, action = 'upsert') {
  if (!product || !product.id) return;

  try {
    if (action === 'delete') {
      console.log(`[Backend DualDBSync] Deleting product ID ${product.id} from Customer DB B...`);
      await customerDb.from('products').delete().eq('id', product.id);
      return;
    }

    const isValidUuid = (val) => typeof val === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(val);

    const syncPayload = {
      id: product.id,
      name: product.name,
      slug: product.slug || product.name?.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-'),
      price: product.price,
      mrp: product.mrp || Math.round(product.price * 1.25),
      description: product.description || '',
      image_url: product.image_url || product.images?.[0] || 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&q=80&w=300',
      images: product.images || (product.image_url ? [product.image_url] : []),
      category_id: isValidUuid(product.category_id) ? product.category_id : null,
      category_name: product.category_name || product.category || 'General',
      category: product.category || product.category_name || 'General',
      brand: product.brand || 'Asali Swad',
      stock: typeof product.stock === 'number' ? product.stock : 100,
      stock_count: typeof product.stock === 'number' ? product.stock : 100,
      sku: product.sku || '',
      low_stock_limit: product.low_stock_limit || 5,
      is_active: product.is_active !== false,
      is_approved: product.is_approved !== false && product.approval_status !== 'rejected',
      approval_status: product.approval_status || (product.is_approved ? 'approved' : 'pending'),
      specifications: product.specifications || {},
      offers: product.offers || [],
      packages: product.packages || [],
      status: product.status || (product.stock > 0 ? 'IN_STOCK' : 'OUT_OF_STOCK'),
      updated_at: new Date().toISOString()
    };

    console.log(`[Backend DualDBSync] Syncing Product ID ${product.id} (${product.name}) to Customer DB B...`);
    const { error } = await customerDb.from('products').upsert([syncPayload], { onConflict: 'id' });
    if (error) {
      console.warn('[Backend DualDBSync Warning] Primary upsert failed, retrying insert:', error);
      await customerDb.from('products').insert([syncPayload]);
    } else {
      console.log(`[Backend DualDBSync Success] Product ID ${product.id} synced to Customer DB B.`);
    }
  } catch (err) {
    console.error('[Backend DualDBSync Error] Unexpected error during product sync:', err);
  }
}

export async function syncCategoryToCustomerDb(category, action = 'upsert') {
  if (!category || !category.id) return;

  try {
    if (action === 'delete') {
      console.log(`[Backend DualDBSync] Deleting Category ID ${category.id} from Customer DB B...`);
      await customerDb.from('categories').delete().eq('id', category.id);
      return;
    }

    const syncPayload = {
      id: category.id,
      name: category.name,
      slug: category.slug || category.name?.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-'),
      main_category: category.main_category || 'Grocery',
      image_url: category.image_url || null,
      is_active: category.is_active !== false,
      sort_order: category.sort_order || 0,
      updated_at: new Date().toISOString()
    };

    console.log(`[Backend DualDBSync] Syncing Category ID ${category.id} (${category.name}) to Customer DB B...`);
    const { error } = await customerDb.from('categories').upsert([syncPayload], { onConflict: 'id' });
    if (error) {
      console.warn('[Backend DualDBSync Warning] Category upsert failed, retrying insert:', error);
      await customerDb.from('categories').insert([syncPayload]);
    } else {
      console.log(`[Backend DualDBSync Success] Category ID ${category.id} synced to Customer DB B.`);
    }
  } catch (err) {
    console.error('[Backend DualDBSync Error] Unexpected error during category sync:', err);
  }
}
