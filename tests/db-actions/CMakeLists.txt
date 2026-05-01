function(_cppbessot_db_action_test_common_args out_var test_name script_name)
  set(_args
    "-DCPPBESSOT_TEST_NAME=${test_name}"
    "-DCPPBESSOT_TEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}"
    "-DCPPBESSOT_TEST_MODULE_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
    "-DCPPBESSOT_DB_PGSQL_DEV_CONNSTR=${CPPBESSOT_DB_PGSQL_DEV_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_PROD_CONNSTR=${CPPBESSOT_DB_PGSQL_PROD_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR=${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_TESTS_CONNSTR=${CPPBESSOT_DB_PGSQL_TESTS_CONNSTR}"
    "-DCPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND=${CPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND}"
    "-DCPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND=${CPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND}"
    "-DCPPBESSOT_DB_ACTION_TEST_SCRIPT=${CMAKE_CURRENT_SOURCE_DIR}/scripts/${script_name}")
  set(${out_var} "${_args}" PARENT_SCOPE)
endfunction()

function(cppbessot_add_db_action_test test_name script_name)
  _cppbessot_db_action_test_common_args(_test_args "${test_name}" "${script_name}")
  add_test(
    NAME ${test_name}
    COMMAND "${CMAKE_COMMAND}" ${_test_args} -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/${script_name}")
endfunction()

function(cppbessot_add_real_pgsql_db_action_test test_name script_name)
  find_program(_psql psql)
  if(NOT _psql)
    message(STATUS "Skipping real PostgreSQL db-action test `${test_name}` because `psql` is not available.")
    return()
  endif()
  find_program(_pg_dump pg_dump)
  if(NOT _pg_dump)
    message(STATUS "Skipping real PostgreSQL db-action test `${test_name}` because `pg_dump` is not available.")
    return()
  endif()

  if("${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" STREQUAL "")
    message(STATUS "Skipping real PostgreSQL db-action test `${test_name}` because CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR is empty.")
    return()
  endif()

  foreach(_required_var IN LISTS ARGN)
    if("${${_required_var}}" STREQUAL "")
      message(STATUS "Skipping real PostgreSQL db-action test `${test_name}` because ${_required_var} is empty.")
      return()
    endif()
  endforeach()

  _cppbessot_db_action_test_common_args(_test_args "${test_name}" "${script_name}")
  add_test(
    NAME ${test_name}
    COMMAND "${CMAKE_COMMAND}" ${_test_args} -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/${script_name}")
  set_tests_properties(${test_name} PROPERTIES RUN_SERIAL TRUE)
endfunction()

cppbessot_add_db_action_test(cppbessot_db_action_invalid_target invalid_target.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_mapping missing_mapping.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_ambiguous_mapping ambiguous_mapping.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_migrate_with missing_migrate_with.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_migration_dir missing_migration_dir.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_proddev_createfrom_illegal proddev_createfrom_illegal.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_createfrom sqlite_createfrom.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_tests_createfrom sqlite_tests_createfrom.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_invalid_sql sqlite_invalid_sql.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_migrate sqlite_migrate.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_proddev_stale sqlite_proddev_stale.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_proddev_clone sqlite_proddev_clone.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_createfrom_mock pgsql_createfrom_mock.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_tests_createfrom_mock pgsql_tests_createfrom_mock.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_migrate_order pgsql_migrate_order.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_stale_abort pgsql_stale_abort.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_backfill_env_no_structural backfill_env_no_structural.cmake)
cppbessot_add_real_pgsql_db_action_test(
  cppbessot_db_action_pgsql_createfrom_real
  pgsql_createfrom_real.cmake
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_add_real_pgsql_db_action_test(
  cppbessot_db_action_pgsql_migrate_real
  pgsql_migrate_real.cmake
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_add_real_pgsql_db_action_test(
  cppbessot_db_action_pgsql_proddev_clone_real
  pgsql_proddev_clone_real.cmake
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_add_real_pgsql_db_action_test(
  cppbessot_db_action_pgsql_proddev_stale_real
  pgsql_proddev_stale_real.cmake
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_add_real_pgsql_db_action_test(
  cppbessot_db_action_pgsql_backfill_real
  pgsql_backfill_real.cmake
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_add_db_action_test(cppbessot_db_action_regression regression_targets.cmake)
