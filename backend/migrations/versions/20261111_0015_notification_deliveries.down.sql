DROP FUNCTION IF EXISTS memora_notifications_record_delivery(uuid, text, text, text, text, text, uuid, text, text, text, text, timestamptz);
DROP FUNCTION IF EXISTS memora_notifications_reminders_sent(uuid, text, date);
DROP FUNCTION IF EXISTS memora_notifications_delivery_exists(uuid, text);
DROP TRIGGER IF EXISTS notification_deliveries_append_only ON notification_deliveries;
DROP FUNCTION IF EXISTS memora_forbid_notification_delivery_mutation();
DROP TABLE IF EXISTS notification_deliveries;
