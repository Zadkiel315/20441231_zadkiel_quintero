
-- =====================================================
-- ACTIVIDAD 4: REVISAR pg_hba.conf
-- =====================================================

SELECT
    type,
    database,
    user_name,
    address,
    auth_method
FROM pg_hba_file_rules;
