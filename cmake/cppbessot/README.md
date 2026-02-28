# CppBeSSOT CMake Module

## Quick include from a parent project

```cmake
# Optional overrides before include:
set(CPPBESSOT_WORKDIR "db")
set(DB_SCHEMA_VERSION_TO_GENERATE "v1.1")
set(DB_SCHEMA_MIGRATION_VERSION_FROM "v1.1")
set(DB_SCHEMA_MIGRATION_VERSION_TO "v1.2")

include(path/to/cppbessot/cmake/cppbessot/CppBeSSOT.cmake)
```

By default the include auto-registers targets and libraries. To disable auto setup:

```cmake
set(CPPBESSOT_AUTO_ENABLE OFF)
include(path/to/cppbessot/cmake/cppbessot/CppBeSSOT.cmake)
cppbessot_enable()
```
