-- Consolidated init script for UniScrape database
-- Uses psql variable substitution with :'VAR' syntax
-- Variables are passed via psql -v flags by the entrypoint script

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE USER uniscrape WITH PASSWORD :'UNISCRAPE_PASSWORD';
CREATE USER staging_user WITH PASSWORD :'STAGING_PASSWORD';

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;

GRANT ALL PRIVILEGES ON SCHEMA public TO uniscrape;
GRANT USAGE ON SCHEMA staging TO staging_user;
GRANT USAGE ON SCHEMA analytics TO uniscrape;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO uniscrape;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging GRANT SELECT ON TABLES TO staging_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT, INSERT, UPDATE ON TABLES TO uniscrape;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    key_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    scopes TEXT[],
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scrape_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    params JSONB,
    result_count INTEGER DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS scrape_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES scrape_jobs(id) ON DELETE CASCADE,
    data JSONB NOT NULL,
    source VARCHAR(255),
    scraped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS listening_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    track_id VARCHAR(255),
    artist VARCHAR(255),
    album VARCHAR(255),
    listened_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duration_seconds INTEGER,
    metadata JSONB
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY users_policy ON users FOR ALL USING (id = current_setting('app.current_user_id')::UUID);

ALTER TABLE listening_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY listening_stats_policy ON listening_stats FOR ALL USING (user_id = current_setting('app.current_user_id')::UUID);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_scrape_jobs_user_id ON scrape_jobs(user_id);
CREATE INDEX idx_scrape_jobs_status ON scrape_jobs(status);
CREATE INDEX idx_scrape_results_job_id ON scrape_results(job_id);
CREATE INDEX idx_listening_stats_user_id ON listening_stats(user_id);
CREATE INDEX idx_listening_stats_listened_at ON listening_stats(listened_at);

CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO analytics.audit_log (table_name, operation, new_data, changed_at)
        VALUES (TG_TABLE_NAME, 'INSERT', to_jsonb(NEW), NOW());
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO analytics.audit_log (table_name, operation, old_data, new_data, changed_at)
        VALUES (TG_TABLE_NAME, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), NOW());
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO analytics.audit_log (table_name, operation, old_data, changed_at)
        VALUES (TG_TABLE_NAME, 'DELETE', to_jsonb(OLD), NOW());
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS analytics.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(255),
    operation VARCHAR(50),
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP WITH TIME ZONE
);

-- Audit triggers on all tables
CREATE TRIGGER audit_users
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_scrape_jobs
    AFTER INSERT OR UPDATE OR DELETE ON scrape_jobs
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_scrape_results
    AFTER INSERT OR UPDATE OR DELETE ON scrape_results
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_listening_stats
    AFTER INSERT OR UPDATE OR DELETE ON listening_stats
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
