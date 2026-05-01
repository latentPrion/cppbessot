include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_real_pgsql_support()
cppbessot_test_require_var(CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_test_case_dir(_case_dir)
cppbessot_test_pgsql_isolated_connstr(_prod_connstr "${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" "prod")
cppbessot_test_pgsql_isolated_connstr(_proddev_connstr "${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" "proddev")

cppbessot_test_pgsql_reset_database("${_prod_connstr}")
cppbessot_test_pgsql_drop_database("${_proddev_connstr}")
cppbessot_test_pgsql_exec(
  "${_prod_connstr}"
  "CREATE TABLE sample(id TEXT PRIMARY KEY); INSERT INTO sample(id) VALUES ('prod-row');")

cppbessot_test_pgsql_clone_command(
  _clone_command
  "${_prod_connstr}"
  "${_proddev_connstr}")
cppbessot_test_cache_string_setting(_prod_setting "CPPBESSOT_DB_PGSQL_PROD_CONNSTR" "${_prod_connstr}")
cppbessot_test_cache_string_setting(_proddev_setting "CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR" "${_proddev_connstr}")
cppbessot_test_cache_string_setting(_clone_setting "CPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND" "${_clone_command}")
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_TARGET \"proddev\" CACHE STRING \"\")\n"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "${_prod_setting}"
  "${_proddev_setting}"
  "${_clone_setting}")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/migrations/v1.0-v1.1/postgre/01-migrate.sql"
  "ALTER TABLE sample ADD COLUMN note TEXT;\n"
  "UPDATE sample SET note = 'cloned' WHERE id = 'prod-row';\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_migrate pgsql proddev clone real")

cppbessot_test_pgsql_query_scalar(_proddev_note "${_proddev_connstr}" "SELECT note FROM sample WHERE id='prod-row';")
if(NOT "${_proddev_note}" STREQUAL "cloned")
  message(FATAL_ERROR "Expected migrated proddev clone to contain note column, got `${_proddev_note}`.")
endif()
cppbessot_test_pgsql_query_scalar(
  _prod_note_column_count
  "${_prod_connstr}"
  "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'sample' AND column_name = 'note';")
if(NOT "${_prod_note_column_count}" STREQUAL "0")
  message(FATAL_ERROR "Expected prod database to remain unchanged after proddev migration.")
endif()

cppbessot_test_pgsql_drop_database("${_proddev_connstr}")
cppbessot_test_pgsql_drop_database("${_prod_connstr}")
