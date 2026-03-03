cmake_minimum_required(VERSION 3.20)
project(cppbessot LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED DB_SCHEMA_DIR_TO_GENERATE OR "${DB_SCHEMA_DIR_TO_GENERATE}" STREQUAL "")
  message(FATAL_ERROR
    "Set DB_SCHEMA_DIR_TO_GENERATE to the exact schema directory basename to test, for example -DDB_SCHEMA_DIR_TO_GENERATE=v1.2.")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/CppBeSSOT.cmake")

include(CTest)

if(BUILD_TESTING)
  add_subdirectory(tests EXCLUDE_FROM_ALL)
endif()
