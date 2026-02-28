# CPPBESSOT (C++ BackEnd Single Source of Truth):

A framework that uses OpenAI to maintain a single source of truth for the data model of a software project. It generates C++ headers, JSON serdes, ODB-based ORM headers, DB migrations, Typescript types and Zod schemas. I.e: a type-safe backend-to-frontend data model manager.

Basically, it enables one to write a web application whose backend is written in C++. This C++ web application can communicate seamlessly with a Typescript frontend without losing type-safety. We leverage Zod to enforce type safety. So you get type-safety from end to end. From C++ through to the Typescript frontend.

It works by specifying the data model in OpenAPI. Then the OpenAPI model is transpiled into both C++ headers (with JSON serdes and ODB ORM for your database of choice) and Typescript types with Zod schema descriptions.

## CMake integration

Reusable CMake entry point for embedding in a larger project:

- `cmake/CppBeSSOT.cmake`

The primary schema root folder is configurable via:

- `CPPBESSOT_WORKDIR` (defaults to `db`)

## Simple Integration Guide

### 1) Add the module from your parent project

```cmake
# Parent project CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(MyApp LANGUAGES CXX)

# Optional: where schema versions live (default is "db")
set(CPPBESSOT_WORKDIR "db")

# Required for generation/library selection
set(DB_SCHEMA_VERSION_TO_GENERATE "v1.1")

# Optional: only needed if you will run db_gen_migrations
# set(DB_SCHEMA_MIGRATION_VERSION_FROM "v1.1")
# set(DB_SCHEMA_MIGRATION_VERSION_TO "v1.2")

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
  -DDB_SCHEMA_MIGRATION_VERSION_FROM=v1.1 \
  -DDB_SCHEMA_MIGRATION_VERSION_TO=v1.2
cmake --build build --target db_gen_migrations
```

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
