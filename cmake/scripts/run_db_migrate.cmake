cmake_minimum_required(VERSION 3.16)

include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionCommon.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionTargetResolution.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionBackfill.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionSqlApply.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotDbActionClone.cmake")

cppbessot_db_action_require_var(CPPBESSOT_PROJECT_SOURCE_DIR)
cppbessot_db_action_require_var(CPPBESSOT_WORKDIR)
cppbessot_db_action_require_var(DB_MIGRATE_WITH)
cppbessot_db_action_require_var(DB_TARGET)
cppbessot_db_action_require_var(DB_SCHEMA_DIR_TO_GENERATE)
cppbessot_db_action_require_var(DB_CREATEFROM_SCHEMA_DIR)

cppbessot_db_action_validate_db_target("${DB_TARGET}")
cppbessot_db_action_assert_migration_dir_exists("${DB_MIGRATE_WITH}")
cppbessot_db_action_resolve_backend_for_target(
  _backend
  _sqlite_path
  _pgsql_connstr
  "${DB_TARGET}")
cppbessot_db_action_prepare_proddev(
  "${DB_TARGET}"
  "${_backend}"
  "${DB_MIGRATE_PRODDEV_USE_STALE}"
  "${_sqlite_path}"
  "${_pgsql_connstr}")
cppbessot_db_action_backend_subdir(_backend_subdir "${_backend}")
cppbessot_db_action_get_migration_dir_path(_migration_dir "${DB_MIGRATE_WITH}")
set(_sql_dir "${_migration_dir}/${_backend_subdir}")
cppbessot_db_action_collect_nonempty_sql_files(_sql_files "${_sql_dir}")
cppbessot_db_action_get_hook_path(_pre_hook "${_migration_dir}" "pre-structural-backfill.sh")
cppbessot_db_action_get_hook_path(_post_hook "${_migration_dir}" "post-structural-backfill.sh")

cppbessot_db_action_run_hook(
  "${_pre_hook}"
  "${DB_TARGET}"
  "${_backend}"
  "${_migration_dir}"
  "${DB_MIGRATE_WITH}"
  "${DB_SCHEMA_DIR_TO_GENERATE}"
  "${DB_CREATEFROM_SCHEMA_DIR}"
  "${_sqlite_path}"
  "${_pgsql_connstr}")

if(_sql_files)
  if("${_backend}" STREQUAL "sqlite")
    cppbessot_db_action_apply_sqlite_files("${_sqlite_path}" ${_sql_files})
  else()
    cppbessot_db_action_apply_pgsql_files("${_pgsql_connstr}" ${_sql_files})
  endif()
endif()

cppbessot_db_action_run_hook(
  "${_post_hook}"
  "${DB_TARGET}"
  "${_backend}"
  "${_migration_dir}"
  "${DB_MIGRATE_WITH}"
  "${DB_SCHEMA_DIR_TO_GENERATE}"
  "${DB_CREATEFROM_SCHEMA_DIR}"
  "${_sqlite_path}"
  "${_pgsql_connstr}")
