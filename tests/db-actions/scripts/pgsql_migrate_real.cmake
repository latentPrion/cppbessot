include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_real_pgsql_support()
cppbessot_test_require_var(CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
cppbessot_test_case_dir(_case_dir)
cppbessot_test_pgsql_isolated_connstr(_dev_connstr "${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" "dev")

cppbessot_test_pgsql_reset_database("${_dev_connstr}")
cppbessot_test_pgsql_exec(
  "${_dev_connstr}"
  "CREATE TABLE sample(id TEXT PRIMARY KEY); INSERT INTO sample(id) VALUES ('row-1');")

cppbessot_test_cache_string_setting(_dev_setting "CPPBESSOT_DB_PGSQL_DEV_CONNSTR" "${_dev_connstr}")
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "${_dev_setting}")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/migrations/v1.0-v1.1/postgre/01-migrate.sql"
  "ALTER TABLE sample ADD COLUMN note TEXT;\n"
  "UPDATE sample SET note = 'migrated' WHERE id = 'row-1';\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_migrate pgsql real")

cppbessot_test_pgsql_query_scalar(_note "${_dev_connstr}" "SELECT note FROM sample WHERE id='row-1';")
if(NOT "${_note}" STREQUAL "migrated")
  message(FATAL_ERROR "Expected PostgreSQL migration to set note column, got `${_note}`.")
endif()

cppbessot_test_pgsql_drop_database("${_dev_connstr}")
