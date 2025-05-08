-- Create schemas
CREATE SCHEMA IF NOT EXISTS stripe;
CREATE SCHEMA IF NOT EXISTS api;
CREATE SCHEMA IF NOT EXISTS blog;
CREATE SCHEMA IF NOT EXISTS reference;

-- Set up extensions for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types for status fields
CREATE TYPE reference.subscription_status AS ENUM (
  'trialing',
  'active',
  'canceled',
  'incomplete',
  'incomplete_expired',
  'past_due',
  'unpaid',
  'paused'
);

-- Set up necessary permissions for RLS
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA stripe GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA api GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA blog GRANT ALL ON TABLES TO postgres, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA reference GRANT ALL ON TABLES TO postgres, service_role; 