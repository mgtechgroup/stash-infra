REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO uniscrape;
GRANT USAGE ON SCHEMA public TO staging_user;

SET password_encryption = 'scram-sha-256';

ALTER USER uniscrape CONNECTION LIMIT 50;
ALTER USER staging_user CONNECTION LIMIT 10;

CREATE ROLE readonly;
GRANT CONNECT ON DATABASE uniscrape TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT USAGE ON SCHEMA staging TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT SELECT ON TABLES TO readonly;

CREATE ROLE backup_role;
GRANT CONNECT ON DATABASE uniscrape TO backup_role;
GRANT USAGE ON SCHEMA public TO backup_role;
GRANT USAGE ON SCHEMA staging TO backup_role;
GRANT USAGE ON SCHEMA analytics TO backup_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_role;
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO backup_role;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO backup_role;

ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM SET log_min_duration_statement = 1000;
ALTER SYSTEM SET statement_timeout = '30s';
ALTER SYSTEM SET idle_in_transaction_session_timeout = '60s';
SELECT pg_reload_conf();
