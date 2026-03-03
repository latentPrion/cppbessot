include_guard(GLOBAL)

include(CMakeParseArguments)
include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbDependencyCheck.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbSchemaCheck.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenTS.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenZod.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenCpp.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenODB.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenSqlDDL.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbGenMigrations.cmake")

if(NOT DEFINED CPPBESSOT_WORKDIR)
  set(CPPBESSOT_WORKDIR "db" CACHE STRING "CppBeSSOT schema root folder")
endif()

if(NOT DEFINED DB_SCHEMA_DIR_TO_GENERATE)
  set(DB_SCHEMA_DIR_TO_GENERATE "v1.1" CACHE STRING "Schema directory basename under CPPBESSOT_WORKDIR to generate artifacts for")
endif()

if(NOT DEFINED DB_SCHEMA_DIR_MIGRATION_FROM)
  set(DB_SCHEMA_DIR_MIGRATION_FROM "" CACHE STRING
    "Optional source schema directory basename for migration generation")
endif()

if(NOT DEFINED DB_SCHEMA_DIR_MIGRATION_TO)
  set(DB_SCHEMA_DIR_MIGRATION_TO "" CACHE STRING
    "Optional target schema directory basename for migration generation")
endif()

if(NOT DEFINED DB_SCHEMA_CHANGES_ARE_ERROR)
  option(DB_SCHEMA_CHANGES_ARE_ERROR "Treat dirty schema changes as hard CMake error" OFF)
endif()

if(NOT DEFINED CPPBESSOT_AUTO_ENABLE)
  option(CPPBESSOT_AUTO_ENABLE "Auto-register CppBeSSOT targets when this file is included" ON)
endif()

function(_cppbessot_try_link_nlohmann target_name)
  # Purpose: Link a target to nlohmann_json when the imported target exists.
  # Inputs:
  #   - target_name: CMake target name to link.
  # Outputs:
  #   - Modifies target link interface; no-op when package target is absent.
  if(TARGET nlohmann_json::nlohmann_json)
    target_link_libraries(${target_name} PUBLIC nlohmann_json::nlohmann_json)
  endif()
endfunction()

function(cppbessot_add_generated_libraries)
  # Purpose: Create consumable libraries from generated model and ODB sources.
  # Inputs:
  #   - SCHEMA_DIR (optional named arg): Schema directory basename to consume.
  #   - DB_SCHEMA_DIR_TO_GENERATE (fallback): Default schema directory basename.
  # Outputs:
  #   - Library targets (when sources exist):
  #       - cppBeSsotOpenAiModelGen
  #       - cppBeSsotOdbSqlite
  #       - cppBeSsotOdbPgSql
  #   - Alias targets:
  #       - cppbessot::openai_model_gen
  #       - cppbessot::odb_sqlite
  #       - cppbessot::odb_pgsql
  #   - Emits warnings if expected source sets are missing.
  set(options)
  set(one_value_args SCHEMA_DIR)
  set(multi_value_args)
  cmake_parse_arguments(CPPB "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

  if(NOT CPPB_SCHEMA_DIR)
    set(CPPB_SCHEMA_DIR "${DB_SCHEMA_DIR_TO_GENERATE}")
  endif()

  cppbessot_validate_schema_dir_name("${CPPB_SCHEMA_DIR}")
  cppbessot_get_schema_dir_path(_version_dir "${CPPB_SCHEMA_DIR}")

  set(_cpp_include_dir "${_version_dir}/generated-cpp-source/include")
  file(GLOB _model_include_dirs LIST_DIRECTORIES true "${_cpp_include_dir}/*/model")

  file(GLOB _model_sources CONFIGURE_DEPENDS
    "${_version_dir}/generated-cpp-source/src/model/*.cpp")
  if(_model_sources)
    add_library(cppBeSsotOpenAiModelGen STATIC ${_model_sources})
    set_target_properties(cppBeSsotOpenAiModelGen PROPERTIES
      OUTPUT_NAME "cppBeSsotOpenAiModelGen"
      POSITION_INDEPENDENT_CODE ON)
    target_include_directories(cppBeSsotOpenAiModelGen PUBLIC "${_cpp_include_dir}")
    _cppbessot_try_link_nlohmann(cppBeSsotOpenAiModelGen)
    add_library(cppbessot::openai_model_gen ALIAS cppBeSsotOpenAiModelGen)
  else()
    message(WARNING "No generated C++ model sources found for ${CPPB_SCHEMA_DIR}; skipping libcppBeSsotOpenAiModelGen.")
  endif()

  file(GLOB _sqlite_odb_sources CONFIGURE_DEPENDS
    "${_version_dir}/generated-odb-source/sqlite/*-odb.cxx")
  if(_sqlite_odb_sources)
    add_library(cppBeSsotOdbSqlite SHARED ${_sqlite_odb_sources})
    set_target_properties(cppBeSsotOdbSqlite PROPERTIES
      OUTPUT_NAME "cppBeSsotOdbSqlite"
      POSITION_INDEPENDENT_CODE ON)
    target_include_directories(cppBeSsotOdbSqlite PUBLIC
      "${_cpp_include_dir}"
      "${_version_dir}/generated-odb-source/sqlite"
      ${_model_include_dirs})
    add_library(cppbessot::odb_sqlite ALIAS cppBeSsotOdbSqlite)
  else()
    message(WARNING "No generated sqlite ODB sources found for ${CPPB_SCHEMA_DIR}; skipping libcppBeSsotOdbSqlite.")
  endif()

  file(GLOB _pgsql_odb_sources CONFIGURE_DEPENDS
    "${_version_dir}/generated-odb-source/postgre/*-odb.cxx")
  if(_pgsql_odb_sources)
    add_library(cppBeSsotOdbPgSql SHARED ${_pgsql_odb_sources})
    set_target_properties(cppBeSsotOdbPgSql PROPERTIES
      OUTPUT_NAME "cppBeSsotOdbPgSql"
      POSITION_INDEPENDENT_CODE ON)
    target_include_directories(cppBeSsotOdbPgSql PUBLIC
      "${_cpp_include_dir}"
      "${_version_dir}/generated-odb-source/postgre"
      ${_model_include_dirs})
    add_library(cppbessot::odb_pgsql ALIAS cppBeSsotOdbPgSql)
  else()
    message(WARNING "No generated postgre ODB sources found for ${CPPB_SCHEMA_DIR}; skipping libcppBeSsotOdbPgSql.")
  endif()
endfunction()

function(cppbessot_enable)
  # Purpose: Entry-point orchestration for dependency checks, custom generation
  #          targets, aggregate targets, and generated library registration.
  # Inputs:
  #   - CPPBESSOT_WORKDIR
  #   - DB_SCHEMA_DIR_TO_GENERATE
  #   - DB_SCHEMA_DIR_MIGRATION_FROM
  #   - DB_SCHEMA_DIR_MIGRATION_TO
  #   - DB_SCHEMA_CHANGES_ARE_ERROR (optional behavior control)
  # Outputs:
  #   - Custom targets:
  #       - db_check_schema_changes
  #       - db_gen_ts
  #       - db_gen_zod
  #       - db_gen_cpp_headers
  #       - db_gen_odb_logic
  #       - db_gen_sql_ddl
  #       - db_gen_migrations
  #       - db_gen_orm_serdes_and_zod
  #   - Generated library targets for selected schema version.
  cppbessot_initialize_paths()

  cppbessot_validate_schema_dir_name("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_assert_schema_dir_exists("${DB_SCHEMA_DIR_TO_GENERATE}")

  cppbessot_check_dependencies()

  cppbessot_add_db_check_schema_changes_target()
  cppbessot_add_db_gen_ts_target("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_add_db_gen_zod_target("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_add_db_gen_cpp_target("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_add_db_gen_odb_target("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_add_db_gen_sql_ddl_target("${DB_SCHEMA_DIR_TO_GENERATE}")
  if(NOT "${DB_SCHEMA_DIR_MIGRATION_FROM}" STREQUAL ""
     AND NOT "${DB_SCHEMA_DIR_MIGRATION_TO}" STREQUAL "")
    cppbessot_validate_schema_dir_name("${DB_SCHEMA_DIR_MIGRATION_FROM}")
    cppbessot_validate_schema_dir_name("${DB_SCHEMA_DIR_MIGRATION_TO}")
    cppbessot_assert_schema_dir_exists("${DB_SCHEMA_DIR_MIGRATION_FROM}")
    cppbessot_assert_schema_dir_exists("${DB_SCHEMA_DIR_MIGRATION_TO}")
    cppbessot_add_db_gen_migrations_target(
      "${DB_SCHEMA_DIR_MIGRATION_FROM}"
      "${DB_SCHEMA_DIR_MIGRATION_TO}")
  else()
    add_custom_target(db_gen_migrations
      COMMAND "${CMAKE_COMMAND}" -E echo
              "Set DB_SCHEMA_DIR_MIGRATION_FROM and DB_SCHEMA_DIR_MIGRATION_TO to enable migration generation."
      COMMAND "${CMAKE_COMMAND}" -E false
      VERBATIM
    )
    set_target_properties(db_gen_migrations PROPERTIES EXCLUDE_FROM_ALL TRUE)
  endif()

  add_custom_target(db_gen_orm_serdes_and_zod)
  add_dependencies(db_gen_orm_serdes_and_zod
    db_gen_ts
    db_gen_zod
    db_gen_cpp_headers
    db_gen_odb_logic
    db_gen_sql_ddl)
  set_target_properties(db_gen_orm_serdes_and_zod PROPERTIES EXCLUDE_FROM_ALL TRUE)

  cppbessot_add_generated_libraries(SCHEMA_DIR "${DB_SCHEMA_DIR_TO_GENERATE}")
endfunction()

if(CPPBESSOT_AUTO_ENABLE)
  cppbessot_enable()
endif()
