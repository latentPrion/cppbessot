cmake_minimum_required(VERSION 3.20)
project(cppbessot LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED DB_SCHEMA_DIR_TO_GENERATE OR "${DB_SCHEMA_DIR_TO_GENERATE}" STREQUAL "")
  message(FATAL_ERROR
    "Set DB_SCHEMA_DIR_TO_GENERATE to the exact schema directory basename to test, for example -DDB_SCHEMA_DIR_TO_GENERATE=v1.2.")
endif()

set(CPPBESSOT_ODB_TEST_SQLITE_CONNSTR "" CACHE STRING
  "Optional SQLite connection string for ODB runtime tests")
set(CPPBESSOT_ODB_TEST_PGSQL_CONNSTR "" CACHE STRING
  "Optional PostgreSQL conninfo string for ODB runtime tests")

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/CppBeSSOT.cmake")

if(NOT DEFINED BUILD_TESTING)
  set(BUILD_TESTING OFF CACHE BOOL "Build cppbessot tests" FORCE)
endif()

include(CTest)

if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
