# cppbessot

`cppbessot` is a CMake-driven schema pipeline for projects that keep their application data model in OpenAPI and need consistent generated artifacts across C++, TypeScript, Zod, ODB, SQL DDL, and database migrations.

The OpenAPI file under a schema directory is the single source of truth. From that, `cppbessot` can:

- generate C++ model headers and JSON serdes sources
- generate ODB ORM sources for SQLite and PostgreSQL
- generate SQL DDL snapshots for SQLite and PostgreSQL
- generate TypeScript types
- generate Zod schemas
- generate SQL migration artifacts between two schema versions
- build linkable generated C++ libraries
- run live DB actions against `dev`, `prod`, `proddev`, or `tests`

## Repository Layout

The embedded module entry point is:

- `cmake/CppBeSSOT.cmake`

The repo also ships test fixtures under:

- `db/test-schema-v1.1`
- `db/test-schema-v1.2`

Each schema directory is expected to look roughly like this:

```text
<CPPBESSOT_WORKDIR>/<schema-dir>/
  openapi/openapi.yaml
  generated-cpp-source/
  generated-odb-source/
  generated-sql-ddl/
  generated-ts-types/
  generated-zod/
```

Migration artifacts live under:

```text
<CPPBESSOT_WORKDIR>/migrations/<from>-<to>/
  sqlite/
  postgre/
  pre-structural-backfill.sh          # optional
  post-structural-backfill.sh         # optional
```

## Configure-Time Requirements

`cppbessot` checks its dependencies during configure.

Always required:

- `git`
- `java`
- `npm`
- `npx`
- `odb`
- `sqlite3` CLI
- SQLite development headers and client library
- PostgreSQL development headers and client library
- `nlohmann_json`
- npm packages:
  - `@openapitools/openapi-generator-cli`
  - `openapi-zod-client`

Conditionally required:

- `psql`
  - required when PostgreSQL live DB actions are configured
  - required when real PostgreSQL db-action tests are configured

## Top-Level CMake Configuration

When configuring the standalone `cppbessot` repo itself, `DB_SCHEMA_DIR_TO_GENERATE` must be set explicitly:

```bash
cmake -S cmake/cppbessot -B build-cppbessot -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.2
```

The standalone top-level file also exposes these DB target mapping cache variables:

- `CPPBESSOT_DB_SQLITE_PROD_PATH`
- `CPPBESSOT_DB_SQLITE_DEV_PATH`
- `CPPBESSOT_DB_SQLITE_PRODDEV_PATH`
- `CPPBESSOT_DB_SQLITE_TESTS_PATH`
- `CPPBESSOT_DB_PGSQL_PROD_CONNSTR`
- `CPPBESSOT_DB_PGSQL_DEV_CONNSTR`
- `CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR`
- `CPPBESSOT_DB_PGSQL_TESTS_CONNSTR`

## Embedding In A Parent Project

Minimal parent-project integration:

```cmake
cmake_minimum_required(VERSION 3.20)
project(my_app LANGUAGES CXX)

set(CPPBESSOT_WORKDIR "db")
set(DB_SCHEMA_DIR_TO_GENERATE "v1.2")

include(path/to/cppbessot/cmake/CppBeSSOT.cmake)
```

By default, including `CppBeSSOT.cmake` auto-registers all generation targets, live DB action targets, and generated libraries.

If you want manual control:

```cmake
set(CPPBESSOT_AUTO_ENABLE OFF)
include(path/to/cppbessot/cmake/CppBeSSOT.cmake)
cppbessot_enable()
```

## CMake Variables

### Core Schema Variables

- `CPPBESSOT_WORKDIR`
  - default: `db`
  - schema root folder, relative to `PROJECT_SOURCE_DIR` or absolute

- `DB_SCHEMA_DIR_TO_GENERATE`
  - default in module mode: `v1.1`
  - required in standalone top-level configure
  - basename of the schema directory to generate artifacts for

- `DB_SCHEMA_DIR_MIGRATION_FROM`
  - default: empty
  - source schema basename for `db_gen_migrations`

- `DB_SCHEMA_DIR_MIGRATION_TO`
  - default: empty
  - target schema basename for `db_gen_migrations`

- `DB_SCHEMA_CHANGES_ARE_ERROR`
  - default: `OFF`
  - used by schema-drift checking logic

- `CPPBESSOT_AUTO_ENABLE`
  - default: `ON`
  - when `ON`, including `CppBeSSOT.cmake` immediately registers targets and libraries

### Live DB Action Variables

- `DB_TARGET`
  - default: `dev`
  - selected live DB target for `db_createfrom` and `db_migrate`
  - allowed values: `prod`, `proddev`, `dev`, `tests`

- `DB_CREATEFROM_SCHEMA_DIR`
  - default: `DB_SCHEMA_DIR_TO_GENERATE`
  - schema basename whose generated SQL DDL should be used by `db_createfrom`

- `DB_MIGRATE_WITH`
  - default: empty
  - migration directory basename under `<CPPBESSOT_WORKDIR>/migrations`
  - example: `v1.1-v1.2`

- `DB_MIGRATE_PRODDEV_USE_STALE`
  - default: `OFF`
  - when `ON` and `DB_TARGET=proddev`, reuse the existing proddev target instead of recloning from prod

### SQLite Live DB Mapping Variables

Exactly one backend mapping must be set for the selected `DB_TARGET`.

- `CPPBESSOT_DB_SQLITE_PROD_PATH`
- `CPPBESSOT_DB_SQLITE_DEV_PATH`
- `CPPBESSOT_DB_SQLITE_PRODDEV_PATH`
- `CPPBESSOT_DB_SQLITE_TESTS_PATH`

These point at the SQLite DB file to act on for `prod`, `dev`, `proddev`, or `tests`.

### PostgreSQL Live DB Mapping Variables

- `CPPBESSOT_DB_PGSQL_PROD_CONNSTR`
- `CPPBESSOT_DB_PGSQL_DEV_CONNSTR`
- `CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR`
- `CPPBESSOT_DB_PGSQL_TESTS_CONNSTR`

These are `psql`-compatible PostgreSQL connection strings for `prod`, `dev`, `proddev`, or `tests`.

### Prod-To-Proddev Clone Hook Variables

These are only needed for `DB_TARGET=proddev` when `DB_MIGRATE_PRODDEV_USE_STALE=OFF`.

- `CPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND`
- `CPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND`

They must be shell command strings that clone the `prod` database into `proddev` for the chosen backend.

## Command Targets

All custom targets are `EXCLUDE_FROM_ALL`, so they run only when explicitly requested or when a dependent library is built.

### `db_check_schema_changes`

Purpose:

- checks for git-tracked schema changes under `CPPBESSOT_WORKDIR`

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_CHANGES_ARE_ERROR`

Output:

- no generated files
- emits success/failure diagnostics about dirty schema state

### `db_gen_ts`

Purpose:

- generates TypeScript types from `openapi/openapi.yaml`

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_TO_GENERATE`

Output:

- `<CPPBESSOT_WORKDIR>/<schema>/generated-ts-types/`

### `db_gen_zod`

Purpose:

- generates Zod schemas from `openapi/openapi.yaml`

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_TO_GENERATE`

Output:

- `<CPPBESSOT_WORKDIR>/<schema>/generated-zod/schemas.ts`

### `db_gen_cpp_headers`

Purpose:

- generates C++ model headers and JSON serdes/model sources from OpenAPI

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_TO_GENERATE`

Output:

- `<CPPBESSOT_WORKDIR>/<schema>/generated-cpp-source/include/`
- `<CPPBESSOT_WORKDIR>/<schema>/generated-cpp-source/src/`

### `db_gen_odb_logic`

Purpose:

- generates ODB ORM sources for both SQLite and PostgreSQL
- depends on `db_gen_cpp_headers`

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_TO_GENERATE`

Output:

- `<CPPBESSOT_WORKDIR>/<schema>/generated-odb-source/sqlite/`
- `<CPPBESSOT_WORKDIR>/<schema>/generated-odb-source/postgre/`

### `db_gen_sql_ddl`

Purpose:

- generates SQL DDL snapshots for both SQLite and PostgreSQL
- depends on `db_gen_cpp_headers`

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_TO_GENERATE`

Output:

- `<CPPBESSOT_WORKDIR>/<schema>/generated-sql-ddl/sqlite/`
- `<CPPBESSOT_WORKDIR>/<schema>/generated-sql-ddl/postgre/`

### `db_gen_migrations`

Purpose:

- generates migration SQL artifacts between two schema versions

Primary variables:

- `CPPBESSOT_WORKDIR`
- `DB_SCHEMA_DIR_MIGRATION_FROM`
- `DB_SCHEMA_DIR_MIGRATION_TO`

Output:

- `<CPPBESSOT_WORKDIR>/migrations/<from>-<to>/sqlite/`
- `<CPPBESSOT_WORKDIR>/migrations/<from>-<to>/postgre/`

Notes:

- `from` and `to` must differ
- if either migration variable is empty, `db_gen_migrations` is still registered but intentionally fails with guidance

### `db_gen_orm_serdes_and_zod`

Purpose:

- aggregate generation target

Runs:

- `db_gen_ts`
- `db_gen_zod`
- `db_gen_cpp_headers`
- `db_gen_odb_logic`
- `db_gen_sql_ddl`

Output:

- no unique output of its own
- produces the union of the five generation targets above

### `db_createfrom`

Purpose:

- recreates a live `dev` or `prod` database from pre-generated SQL DDL artifacts

Primary variables:

- `DB_TARGET`
- `DB_CREATEFROM_SCHEMA_DIR`
- one backend mapping for the selected target

Behavior:

- `DB_TARGET=proddev` is illegal and aborts
- validates that `DB_CREATEFROM_SCHEMA_DIR` exists and has `openapi/openapi.yaml`
- chooses backend by inspecting the selected target mapping
- requires non-empty SQL files under:
  - `<schema>/generated-sql-ddl/sqlite/`, or
  - `<schema>/generated-sql-ddl/postgre/`
- SQLite path:
  - deletes the current DB file if it exists
  - recreates parent directories
  - applies non-empty `.sql` files in sorted order using `sqlite3`
- PostgreSQL path:
  - resets the `public` schema in the target DB
  - applies non-empty `.sql` files in sorted order using `psql`

Output:

- a recreated live database matching the chosen schema snapshot

### `db_migrate`

Purpose:

- applies a generated migration directory, plus optional backfill hooks, to the selected live DB target

Primary variables:

- `DB_TARGET`
- `DB_MIGRATE_WITH`
- `DB_MIGRATE_PRODDEV_USE_STALE`
- one backend mapping for the selected target
- optional clone hook variable for `proddev`

Behavior:

- validates that `<CPPBESSOT_WORKDIR>/migrations/<DB_MIGRATE_WITH>` exists
- chooses backend by inspecting the selected target mapping
- for `DB_TARGET=proddev`:
  - if `DB_MIGRATE_PRODDEV_USE_STALE=OFF`, runs the configured clone command first
  - if `DB_MIGRATE_PRODDEV_USE_STALE=ON`, requires that the stale proddev target already exists
- hook order:
  1. `pre-structural-backfill.sh` if present
  2. non-empty structural SQL files for the selected backend if present
  3. `post-structural-backfill.sh` if present
- hooks run with these environment variables:
  - `CPPBESSOT_DB_TARGET`
  - `CPPBESSOT_DB_BACKEND`
  - `CPPBESSOT_DB_MIGRATION_DIR`
  - `CPPBESSOT_DB_MIGRATE_WITH`
  - `CPPBESSOT_DB_SCHEMA_DIR_TO_GENERATE`
  - `CPPBESSOT_DB_CREATEFROM_SCHEMA_DIR`
  - `CPPBESSOT_DB_SQLITE_PATH`
  - `CPPBESSOT_DB_PGSQL_CONNSTR`

Output:

- a migrated live database for the selected target

## Generated Library Targets

### `cppbessot_add_generated_cpp_model_libraries()`

Registers:

- `cppBeSsotOpenAiModelGen`
- alias `cppbessot::openai_model_gen`

Behavior:

- depends on `db_gen_cpp_headers`
- building a consumer that links `cppbessot::openai_model_gen` forces model generation first

Consumes generated output from:

- `<schema>/generated-cpp-source/include/`
- `<schema>/generated-cpp-source/src/`

### `cppbessot_add_generated_odb_libraries()`

Registers:

- `cppBeSsotOdbSqlite`
- `cppBeSsotOdbPgSql`
- aliases:
  - `cppbessot::odb_sqlite`
  - `cppbessot::odb_pgsql`

Behavior:

- depends on `db_gen_odb_logic`
- also depends on `db_gen_sql_ddl` so ORM libs stay aligned with the same schema generation pass
- building a consumer that links these libs forces ODB generation first

Consumes generated output from:

- `<schema>/generated-cpp-source/include/`
- `<schema>/generated-odb-source/sqlite/`
- `<schema>/generated-odb-source/postgre/`

### `cppbessot_add_generated_libraries()`

Registers all three generated libraries above.

This is the umbrella library-registration entry point used by `cppbessot_enable()`.

## Sample Workflows

### 1. Generate Everything For One Schema

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2

cmake --build build --target db_gen_orm_serdes_and_zod
```

This produces:

- `generated-ts-types`
- `generated-zod`
- `generated-cpp-source`
- `generated-odb-source`
- `generated-sql-ddl`

### 2. Generate Migration Artifacts Between Two Schemas

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_SCHEMA_DIR_MIGRATION_FROM=v1.1 \
  -DDB_SCHEMA_DIR_MIGRATION_TO=v1.2

cmake --build build --target db_gen_migrations
```

This writes migration SQL under:

- `db/migrations/v1.1-v1.2/sqlite/`
- `db/migrations/v1.1-v1.2/postgre/`

### 3. Link Only The Generated C++ Model Library

```cmake
target_link_libraries(my_app PRIVATE cppbessot::openai_model_gen)
```

That is valid if your application wants generated C++ models and JSON serdes but does not want ODB ORM libraries.

### 4. Link The Full Generated C++ Stack

```cmake
target_link_libraries(my_app PRIVATE
  cppbessot::openai_model_gen
  cppbessot::odb_sqlite
  cppbessot::odb_pgsql
)
```

### 5. Create A Fresh SQLite `dev` Database From The Current Schema

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=dev \
  -DCPPBESSOT_DB_SQLITE_DEV_PATH=/tmp/myapp-dev.sqlite

cmake --build build --target db_gen_sql_ddl
cmake --build build --target db_createfrom
```

This recreates `/tmp/myapp-dev.sqlite` from:

- `db/v1.2/generated-sql-ddl/sqlite/`

### 6. Create A Fresh PostgreSQL `prod` Database Schema Snapshot

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=prod \
  -DCPPBESSOT_DB_PGSQL_PROD_CONNSTR="host=127.0.0.1 port=5432 dbname=myapp_prod user=postgres password=postgres"

cmake --build build --target db_gen_sql_ddl
cmake --build build --target db_createfrom
```

This resets the `public` schema in the target PostgreSQL DB, then reapplies the generated DDL.

### 7. Migrate A SQLite `dev` Database With Optional Backfills

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=dev \
  -DDB_MIGRATE_WITH=v1.1-v1.2 \
  -DCPPBESSOT_DB_SQLITE_DEV_PATH=/tmp/myapp-dev.sqlite

cmake --build build --target db_migrate
```

If present, these run in order:

1. `db/migrations/v1.1-v1.2/pre-structural-backfill.sh`
2. non-empty SQL files under `db/migrations/v1.1-v1.2/sqlite/`
3. `db/migrations/v1.1-v1.2/post-structural-backfill.sh`

### 8. Migrate A `proddev` Clone From `prod`

SQLite example:

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=proddev \
  -DDB_MIGRATE_WITH=v1.1-v1.2 \
  -DCPPBESSOT_DB_SQLITE_PROD_PATH=/srv/myapp/prod.sqlite \
  -DCPPBESSOT_DB_SQLITE_PRODDEV_PATH=/srv/myapp/proddev.sqlite \
  -DCPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND='cp /srv/myapp/prod.sqlite /srv/myapp/proddev.sqlite'

cmake --build build --target db_migrate
```

PostgreSQL example:

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=proddev \
  -DDB_MIGRATE_WITH=v1.1-v1.2 \
  -DCPPBESSOT_DB_PGSQL_PROD_CONNSTR="host=127.0.0.1 port=5432 dbname=myapp_prod user=postgres password=postgres" \
  -DCPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR="host=127.0.0.1 port=5432 dbname=myapp_proddev user=postgres password=postgres" \
  -DCPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND='psql "host=127.0.0.1 port=5432 dbname=postgres user=postgres password=postgres" -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS myapp_proddev;" -c "CREATE DATABASE myapp_proddev TEMPLATE myapp_prod;"'

cmake --build build --target db_migrate
```

### 9. Reuse An Existing Stale `proddev`

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_TO_GENERATE=v1.2 \
  -DDB_TARGET=proddev \
  -DDB_MIGRATE_WITH=v1.1-v1.2 \
  -DDB_MIGRATE_PRODDEV_USE_STALE=ON \
  -DCPPBESSOT_DB_SQLITE_PRODDEV_PATH=/srv/myapp/proddev.sqlite

cmake --build build --target db_migrate
```

This skips the clone step and aborts if the stale target does not already exist.

## Testing

### Configure The Standalone Repo For Tests

```bash
git -C cmake/cppbessot submodule update --init --recursive tests/googletest

cmake -S cmake/cppbessot -B build-cppbessot-tests \
  -DBUILD_TESTING=ON \
  -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.2
```

### Run All Registered Tests

```bash
ctest --test-dir build-cppbessot-tests --output-on-failure
```

### ODB Runtime Tests

Provide DB target mappings:

```bash
cmake -S cmake/cppbessot -B build-cppbessot-tests \
  -DBUILD_TESTING=ON \
  -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.2 \
  -DCPPBESSOT_DB_SQLITE_PRODDEV_PATH=/tmp/cppbessot-odb.sqlite \
  -DCPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR="host=127.0.0.1 port=5432 dbname=cppbessot_odb_test user=postgres password=postgres"
```

### Real PostgreSQL DB-Action Tests

These tests are only registered when all of the following are true:

- `BUILD_TESTING=ON`
- `psql` is available
- the required target connstr variables for the individual test are non-empty

Example:

```bash
cmake -S cmake/cppbessot -B build-cppbessot-tests \
  -DBUILD_TESTING=ON \
  -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.2 \
  -DCPPBESSOT_DB_PGSQL_DEV_CONNSTR="host=127.0.0.1 port=5432 dbname=cppbessot_dev user=postgres password=postgres" \
  -DCPPBESSOT_DB_PGSQL_PROD_CONNSTR="host=127.0.0.1 port=5432 dbname=cppbessot_prod user=postgres password=postgres" \
  -DCPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR="host=127.0.0.1 port=5432 dbname=cppbessot_proddev user=postgres password=postgres"

ctest --test-dir build-cppbessot-tests -R 'cppbessot_db_action_pgsql_.*_real' --output-on-failure
```

## Notes

- Schema directory names must be basenames, not paths.
- `DB_TARGET` must resolve to exactly one backend mapping.
- `db_createfrom` and `db_migrate` operate on pre-generated SQL artifacts. If those artifacts are stale, regenerate them first.
- The PostgreSQL live-action path resets the `public` schema. Use dedicated databases and be deliberate with `prod` mappings.
