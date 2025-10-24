BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
COMMENT ON EXTENSION pgcrypto IS 'mig:00_extensions | enable core extensions - UUIDs via gen_random_uuid';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
COMMENT ON EXTENSION "uuid-ossp" IS 'mig:00_extensions | enable core extensions - compat';

CREATE EXTENSION IF NOT EXISTS pg_trgm;
COMMENT ON EXTENSION pg_trgm IS 'mig:00_extensions | enable core extensions - search, fuzzy';

CREATE EXTENSION IF NOT EXISTS postgis;
COMMENT ON EXTENSION postgis IS 'mig:00_extensions | enable core extensions - geography';

CREATE EXTENSION IF NOT EXISTS btree_gin;
COMMENT ON EXTENSION btree_gin IS 'mig:00_extensions | enable core extensions - btree/gin operator class support';

CREATE EXTENSION IF NOT EXISTS btree_gist;
COMMENT ON EXTENSION btree_gist IS 'mig:00_extensions | enable core extensions - btree/gist operator class support';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
COMMENT ON EXTENSION pg_stat_statements IS 'mig:00_extensions | enable core extensions - track execution statistics';

CREATE EXTENSION IF NOT EXISTS citext;
COMMENT ON EXTENSION citext IS 'mig:00_extensions | enable core extensions - case-insensitive text';

CREATE EXTENSION IF NOT EXISTS unaccent;
COMMENT ON EXTENSION unaccent IS 'mig:00_extensions | enable core extensions - unaccent text';

CREATE EXTENSION IF NOT EXISTS pg_graphql;
COMMENT ON EXTENSION pg_graphql IS 'mig:00_extensions | enable core extensions - GraphQL support';

COMMIT;
