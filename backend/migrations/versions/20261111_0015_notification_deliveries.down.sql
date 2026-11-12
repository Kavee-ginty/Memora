DROP FUNCTION IF EXISTS memora_notifications_record_delivery(uuid, text, text, text, text, text, uuid, text, text, text, text, timestamptz);
DROP FUNCTION IF EXISTS memora_notifications_reminders_sent(uuid, text, date);
DROP FUNCTION IF EXISTS memora_notifications_delivery_exists(uuid, text);
DROP FUNCTION IF EXISTS memora_notifications_expire_stale_sending(timestamptz, interval);
DROP TRIGGER IF EXISTS notification_deliveries_lifecycle ON notification_deliveries;
DROP FUNCTION IF EXISTS memora_protect_notification_delivery();
DROP TABLE IF EXISTS notification_deliveries;
