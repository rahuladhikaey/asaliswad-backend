import cron from 'node-cron';
import { purgeExpiredDeletions } from '../controllers/sellerController.js';

/**
 * Initialize all automated background & cron jobs
 */
export const initCronJobs = () => {
  console.log('⏱️ Initializing ASALISWAD Cron Jobs...');

  // Job 1: Purge expired seller accounts daily at midnight (00:00)
  cron.schedule('0 0 * * *', async () => {
    console.log('⏰ [CRON] Starting Daily Expired Seller Account Purge...');
    try {
      // Mock request and response handlers for internal invocation
      const req = {};
      const res = {
        status: (code) => ({
          json: (data) => console.log(`✅ [CRON] Seller Purge Completed (${code}):`, data)
        })
      };
      const next = (err) => console.error('❌ [CRON] Seller Purge Error:', err);
      
      await purgeExpiredDeletions(req, res, next);
    } catch (error) {
      console.error('❌ [CRON] Failed to execute purgeExpiredDeletions:', error);
    }
  });

  console.log('✅ Cron Jobs Scheduled: [Seller Account Daily Purge @ 00:00]');
};
