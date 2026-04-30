include_guard(GLOBAL)

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

function(_cppbessot_assert_generation_targets_registered consumer_name)
  # Purpose: Ensure split public library registration functions are only used
  #          after generation targets are registered (typically via cppbessot_enable()).
  # Inputs:
  #   - consumer_name: Human-readable function name for diagnostics.
  # Outputs:
  #   - No return value; raises FATAL_ERROR when prerequisites are missing.
  if(NOT TARGET db_gen_cpp_headers OR NOT TARGET db_gen_odb_logic OR NOT TARGET db_gen_sql_ddl)
    message(FATAL_ERROR
      "${consumer_name} requires generation targets to be registered first. "
      "Call cppbessot_enable() before invoking split generated-library registration functions.")
  endif()
endfunction()

function(_cppbessot_add_generated_model_library cpp_include_dir expected_model_headers expected_model_sources)
  set_source_files_properties(${expected_model_headers} ${expected_model_sources}
    PROPERTIES GENERATED TRUE)
  add_library(cppBeSsotOpenAiModelGen STATIC ${expected_model_sources})
  add_dependencies(cppBeSsotOpenAiModelGen db_gen_cpp_headers)
  set_target_properties(cppBeSsotOpenAiModelGen PROPERTIES
    OUTPUT_NAME "cppBeSsotOpenAiModelGen"
    POSITION_INDEPENDENT_CODE ON)
  target_include_directories(cppBeSsotOpenAiModelGen PUBLIC "${cpp_include_dir}")
  _cppbessot_try_link_nlohmann(cppBeSsotOpenAiModelGen)
  add_library(cppbessot::openai_model_gen ALIAS cppBeSsotOpenAiModelGen)
endfunction()

function(_cppbessot_add_generated_sqlite_library
    cpp_include_dir
    model_leaf_include_dir
    version_dir
    expected_sqlite_odb_sources)
  set_source_files_properties(${expected_sqlite_odb_sources} PROPERTIES GENERATED TRUE)
  add_library(cppBeSsotOdbSqlite SHARED ${expected_sqlite_odb_sources})
  # Keep the ODB library aligned with the SQL snapshots emitted from the same schema generation pass.
  add_dependencies(cppBeSsotOdbSqlite
    db_gen_odb_logic
    db_gen_sql_ddl)
  set_target_properties(cppBeSsotOdbSqlite PROPERTIES
    OUTPUT_NAME "cppBeSsotOdbSqlite"
    POSITION_INDEPENDENT_CODE ON)
  target_include_directories(cppBeSsotOdbSqlite PUBLIC
    "${cpp_include_dir}"
    "${model_leaf_include_dir}"
    "${version_dir}/generated-odb-source/sqlite"
    "${CPPBESSOT_SQLITE_INCLUDE_DIR}")
  target_link_libraries(cppBeSsotOdbSqlite PUBLIC
    "${CPPBESSOT_ODB_RUNTIME_LIB}"
    "${CPPBESSOT_ODB_SQLITE_RUNTIME_LIB}")
  add_library(cppbessot::odb_sqlite ALIAS cppBeSsotOdbSqlite)
endfunction()

function(_cppbessot_add_generated_pgsql_library
    cpp_include_dir
    model_leaf_include_dir
    version_dir
    expected_pgsql_odb_sources)
  set_source_files_properties(${expected_pgsql_odb_sources} PROPERTIES GENERATED TRUE)
  add_library(cppBeSsotOdbPgSql SHARED ${expected_pgsql_odb_sources})
  # Keep the ODB library aligned with the SQL snapshots emitted from the same schema generation pass.
  add_dependencies(cppBeSsotOdbPgSql
    db_gen_odb_logic
    db_gen_sql_ddl)
  set_target_properties(cppBeSsotOdbPgSql PROPERTIES
    OUTPUT_NAME "cppBeSsotOdbPgSql"
    POSITION_INDEPENDENT_CODE ON)
  target_include_directories(cppBeSsotOdbPgSql PUBLIC
    "${cpp_include_dir}"
    "${model_leaf_include_dir}"
    "${version_dir}/generated-odb-source/postgre"
    "${CPPBESSOT_PGSQL_INCLUDE_DIR}")
  target_link_libraries(cppBeSsotOdbPgSql PUBLIC
    "${CPPBESSOT_ODB_RUNTIME_LIB}"
    "${CPPBESSOT_ODB_PGSQL_RUNTIME_LIB}")
  add_library(cppbessot::odb_pgsql ALIAS cppBeSsotOdbPgSql)
endfunction()

function(cppbessot_add_generated_cpp_model_libraries)
  # Purpose: Create consumable C++ model library from generated model sources.
  # Inputs:
  #   - DB_SCHEMA_DIR_TO_GENERATE: Schema directory basename under CPPBESSOT_WORKDIR.
  # Outputs:
  #   - Library target:
  #       - cppBeSsotOpenAiModelGen
  #   - Alias target:
  #       - cppbessot::openai_model_gen
  _cppbessot_assert_generation_targets_registered("cppbessot_add_generated_cpp_model_libraries")
  cppbessot_validate_schema_dir_name("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_get_schema_dir_path(_version_dir "${DB_SCHEMA_DIR_TO_GENERATE}")
  set(_cpp_include_dir "${_version_dir}/generated-cpp-source/include")
  cppbessot_get_expected_cpp_model_outputs(
    _expected_model_headers
    _expected_model_sources
    "${DB_SCHEMA_DIR_TO_GENERATE}")

  _cppbessot_add_generated_model_library(
    "${_cpp_include_dir}"
    "${_expected_model_headers}"
    "${_expected_model_sources}")
endfunction()

function(cppbessot_add_generated_odb_libraries)
  # Purpose: Create consumable ODB libraries from generated ODB sources.
  # Inputs:
  #   - DB_SCHEMA_DIR_TO_GENERATE: Schema directory basename under CPPBESSOT_WORKDIR.
  # Outputs:
  #   - Library targets:
  #       - cppBeSsotOdbSqlite
  #       - cppBeSsotOdbPgSql
  #   - Alias targets:
  #       - cppbessot::odb_sqlite
  #       - cppbessot::odb_pgsql
  _cppbessot_assert_generation_targets_registered("cppbessot_add_generated_odb_libraries")
  cppbessot_validate_schema_dir_name("${DB_SCHEMA_DIR_TO_GENERATE}")
  cppbessot_get_schema_dir_path(_version_dir "${DB_SCHEMA_DIR_TO_GENERATE}")

  set(_cpp_include_dir "${_version_dir}/generated-cpp-source/include")
  set(_model_leaf_include_dir "${_cpp_include_dir}/cppbessot/model")
  cppbessot_get_expected_odb_outputs(
    _expected_sqlite_odb_sources
    _expected_pgsql_odb_sources
    "${DB_SCHEMA_DIR_TO_GENERATE}")

  _cppbessot_add_generated_sqlite_library(
    "${_cpp_include_dir}"
    "${_model_leaf_include_dir}"
    "${_version_dir}"
    "${_expected_sqlite_odb_sources}")
  _cppbessot_add_generated_pgsql_library(
    "${_cpp_include_dir}"
    "${_model_leaf_include_dir}"
    "${_version_dir}"
    "${_expected_pgsql_odb_sources}")
endfunction()

function(cppbessot_add_generated_libraries)
  # Purpose: Create consumable libraries from generated model and ODB sources.
  # Inputs:
  #   - DB_SCHEMA_DIR_TO_GENERATE: Schema directory basename under CPPBESSOT_WORKDIR.
  # Outputs:
  #   - Library targets (when sources exist):
  #       - cppBeSsotOpenAiModelGen
  #       - cppBeSsotOdbSqlite
  #       - cppBeSsotOdbPgSql
  #   - Alias targets:
  #       - cppbessot::openai_model_gen
  #       - cppbessot::odb_sqlite
  #       - cppbessot::odb_pgsql
  cppbessot_add_generated_cpp_model_libraries()
  cppbessot_add_generated_odb_libraries()
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
  cppbessot_assert_openapi_exists("${DB_SCHEMA_DIR_TO_GENERATE}")

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

  cppbessot_add_generated_libraries()
endfunction()

if(CPPBESSOT_AUTO_ENABLE)
  cppbessot_enable()
endif()
