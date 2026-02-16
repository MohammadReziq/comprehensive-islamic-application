-- Enable Realtime for tables used by the app (التحديثات المباشرة)
-- See: docs/study_roles_integration.md § 6

ALTER PUBLICATION supabase_realtime ADD TABLE attendance;
ALTER PUBLICATION supabase_realtime ADD TABLE mosques;
ALTER PUBLICATION supabase_realtime ADD TABLE correction_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
