include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbActionCommon.cmake")
set(_CPPBESSOT_DB_ACTION_MIGRATE_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(cppbessot_add_db_migrate_target)
  _cppbessot_db_action_common_cache_args(_common_args)
  _cppbessot_add_db_action_target(
    db_migrate
    "${_CPPBESSOT_DB_ACTION_MIGRATE_DIR}/scripts/run_db_migrate.cmake"
    "Migrating live DB target `${DB_TARGET}` using migration `${DB_MIGRATE_WITH}`"
    ${_common_args}
    "-DDB_MIGRATE_WITH=${DB_MIGRATE_WITH}"
    "-DDB_MIGRATE_PRODDEV_USE_STALE=${DB_MIGRATE_PRODDEV_USE_STALE}"
    "-DCPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND=${CPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND}"
    "-DCPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND=${CPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND}")
endfunction()
