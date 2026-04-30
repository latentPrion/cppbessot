cmake_minimum_required(VERSION 3.16)

include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionCommon.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionTargetResolution.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionSqlApply.cmake")

cppbessot_db_action_require_var(CPPBESSOT_PROJECT_SOURCE_DIR)
cppbessot_db_action_require_var(CPPBESSOT_WORKDIR)
cppbessot_db_action_require_var(DB_CREATEFROM_SCHEMA_DIR)
cppbessot_db_action_require_var(DB_TARGET)

cppbessot_db_action_validate_db_target("${DB_TARGET}")
if("${DB_TARGET}" STREQUAL "proddev")
  message(FATAL_ERROR "db_createfrom does not support DB_TARGET=proddev.")
endif()

cppbessot_db_action_assert_schema_dir_ready("${DB_CREATEFROM_SCHEMA_DIR}")
cppbessot_db_action_resolve_backend_for_target(
  _backend
  _sqlite_path
  _pgsql_connstr
  "${DB_TARGET}")
cppbessot_db_action_backend_subdir(_backend_subdir "${_backend}")
cppbessot_db_action_get_schema_dir_path(_schema_dir "${DB_CREATEFROM_SCHEMA_DIR}")
set(_ddl_dir "${_schema_dir}/generated-sql-ddl/${_backend_subdir}")
cppbessot_db_action_require_nonempty_sql_dir(
  "${_ddl_dir}"
  "db_createfrom cannot continue")
cppbessot_db_action_collect_nonempty_sql_files(_sql_files "${_ddl_dir}")

if("${_backend}" STREQUAL "sqlite")
  cppbessot_db_action_reset_sqlite_db("${_sqlite_path}")
  cppbessot_db_action_apply_sqlite_files("${_sqlite_path}" ${_sql_files})
  return()
endif()

cppbessot_db_action_reset_pgsql_schema("${_pgsql_connstr}")
cppbessot_db_action_apply_pgsql_files("${_pgsql_connstr}" ${_sql_files})
