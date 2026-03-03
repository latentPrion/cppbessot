# CPPBESSOT (C++ BackEnd Single Source of Truth):

A framework that uses OpenAI to maintain a single source of truth for the data model of a software project. It generates C++ headers, JSON serdes, ODB-based ORM headers, DB migrations, Typescript types and Zod schemas. I.e: a type-safe backend-to-frontend data model manager.

Basically, it enables one to write a web application whose backend is written in C++. This C++ web application can communicate seamlessly with a Typescript frontend without losing type-safety. We leverage Zod to enforce type safety. So you get type-safety from end to end. From C++ through to the Typescript frontend.

It works by specifying the data model in OpenAPI. Then the OpenAPI model is transpiled into both C++ headers (with JSON serdes and ODB ORM for your database of choice) and Typescript types with Zod schema descriptions.

## CMake integration

Reusable CMake entry point for embedding in a larger project:

- `cmake/CppBeSSOT.cmake`

The primary schema root folder is configurable via:

- `CPPBESSOT_WORKDIR` (defaults to `db`)

This repo also carries self-contained schema fixtures for test runs:

- `db/test-schema-v1.1`
- `db/test-schema-v1.2`

## Simple Integration Guide

### 1) Add the module from your parent project

```cmake
# Parent project CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(MyApp LANGUAGES CXX)

# Optional: where schema directories live (default is "db")
set(CPPBESSOT_WORKDIR "db")

# Required: exact schema directory basename under CPPBESSOT_WORKDIR
set(DB_SCHEMA_DIR_TO_GENERATE "v1.1")

# Optional: only needed if you will run db_gen_migrations
# set(DB_SCHEMA_DIR_MIGRATION_FROM "v1.1")
# set(DB_SCHEMA_DIR_MIGRATION_TO "v1.2")

include(path/to/cppbessot/cmake/CppBeSSOT.cmake)
```

### 2) Build generation targets manually

```bash
cmake -S . -B build
cmake --build build --target db_gen_orm_serdes_and_zod
cmake --build build --target db_gen_sql_ddl
cmake --build build --target db_check_schema_changes
```

Optional migration generation:

```bash
cmake -S . -B build \
  -DDB_SCHEMA_DIR_MIGRATION_FROM=v1.1 \
  -DDB_SCHEMA_DIR_MIGRATION_TO=v1.2
cmake --build build --target db_gen_migrations
```

### 2b) Build the bundled serdes tests

These tests validate that checked-in generated C++ model code can be compiled and used for JSON round trips. They are owned by `cppbessot`, not by any parent project.

```bash
git submodule update --init --recursive tests/googletest
cmake -S . -B build-tests -DBUILD_TESTING=ON -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.2
cmake --build build-tests --target cpp_serdes_test_schema_v1_2
ctest --test-dir build-tests --output-on-failure
```

The local test fixtures live under `db/test-schema-v1.1` and `db/test-schema-v1.2`. They intentionally differ so migration generation has real additive schema changes to process.

For ODB runtime tests, also provide backend connection strings:

```bash
cmake -S . -B build-tests \
  -DBUILD_TESTING=ON \
  -DDB_SCHEMA_DIR_TO_GENERATE=test-schema-v1.1 \
  -DCPPBESSOT_ODB_TEST_SQLITE_CONNSTR=/tmp/cppbessot-odb-test.sqlite \
  -DCPPBESSOT_ODB_TEST_PGSQL_CONNSTR="host=127.0.0.1 port=5432 dbname=cppbessot_test user=postgres password=postgres"
cmake --build build-tests --target cpp_odb_orm_sqlite_test_schema_v1_1
cmake --build build-tests --target cpp_odb_orm_pgsql_test_schema_v1_1
ctest --test-dir build-tests --output-on-failure
```

Use a dedicated PostgreSQL test database. The ODB runtime tests recreate the schema.
The ODB runtime tests also verify hydration from ORM query result sets by persisting multiple rows, querying them back through `odb::result<T>`, and asserting that distinct field values are materialized correctly for both SQLite and PostgreSQL.
The configured CMake connstring values are baked into the test binaries as defaults, so direct binary execution works without exporting environment variables first. If the matching environment variable is set at runtime, it still overrides the compiled default.

### 3) Link generated libraries

```cmake
target_link_libraries(my_app PRIVATE
  cppbessot::openai_model_gen
  cppbessot::odb_sqlite   # if sqlite odb sources exist
  cppbessot::odb_pgsql    # if postgre odb sources exist
)
```

### Optional manual enable mode

```cmake
set(CPPBESSOT_AUTO_ENABLE OFF)
include(path/to/cppbessot/cmake/CppBeSSOT.cmake)
cppbessot_enable()
```
