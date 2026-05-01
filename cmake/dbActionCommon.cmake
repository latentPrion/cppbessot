include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/dbActionShared.cmake")

function(cppbessot_validate_db_target db_target)
  _cppbessot_db_action_validate_db_target_impl("${db_target}")
endfunction()

function(cppbessot_validate_migration_dir_name migration_dir)
  _cppbessot_db_action_validate_basename(
    "${migration_dir}"
    "Migration directory name"
    "CPPBESSOT_WORKDIR/migrations")
endfunction()

function(cppbessot_get_migration_dir_path out_var migration_dir)
  cppbessot_validate_migration_dir_name("${migration_dir}")
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(${out_var} "${_workdir}/migrations/${migration_dir}" PARENT_SCOPE)
endfunction()

function(cppbessot_assert_migration_dir_exists migration_dir)
  cppbessot_get_migration_dir_path(_migration_dir_path "${migration_dir}")
  if(NOT IS_DIRECTORY "${_migration_dir_path}")
    message(FATAL_ERROR "Migration directory does not exist: ${_migration_dir_path}")
  endif()
endfunction()

function(_cppbessot_db_action_common_cache_args out_var)
  set(_args
    "-DCPPBESSOT_PROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
    "-DCPPBESSOT_WORKDIR=${CPPBESSOT_WORKDIR}"
    "-DDB_SCHEMA_DIR_TO_GENERATE=${DB_SCHEMA_DIR_TO_GENERATE}"
    "-DDB_CREATEFROM_SCHEMA_DIR=${DB_CREATEFROM_SCHEMA_DIR}"
    "-DDB_TARGET=${DB_TARGET}"
    "-DCPPBESSOT_DB_SQLITE_PROD_PATH=${CPPBESSOT_DB_SQLITE_PROD_PATH}"
    "-DCPPBESSOT_DB_SQLITE_DEV_PATH=${CPPBESSOT_DB_SQLITE_DEV_PATH}"
    "-DCPPBESSOT_DB_SQLITE_PRODDEV_PATH=${CPPBESSOT_DB_SQLITE_PRODDEV_PATH}"
    "-DCPPBESSOT_DB_SQLITE_TESTS_PATH=${CPPBESSOT_DB_SQLITE_TESTS_PATH}"
    "-DCPPBESSOT_DB_PGSQL_PROD_CONNSTR=${CPPBESSOT_DB_PGSQL_PROD_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_DEV_CONNSTR=${CPPBESSOT_DB_PGSQL_DEV_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR=${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_TESTS_CONNSTR=${CPPBESSOT_DB_PGSQL_TESTS_CONNSTR}")
  set(${out_var} "${_args}" PARENT_SCOPE)
endfunction()

function(_cppbessot_add_db_action_target target_name script_path comment_text)
  add_custom_target(${target_name}
    COMMAND "${CMAKE_COMMAND}" ${ARGN} -P "${script_path}"
    COMMENT "${comment_text}"
    VERBATIM
  )
  set_target_properties(${target_name} PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
