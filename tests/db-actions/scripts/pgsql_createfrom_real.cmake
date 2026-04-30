include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_real_pgsql_support()
cppbessot_test_require_var(CPPBESSOT_DB_PGSQL_DEV_CONNSTR)
cppbessot_test_case_dir(_case_dir)
cppbessot_test_pgsql_isolated_connstr(_dev_connstr "${CPPBESSOT_DB_PGSQL_DEV_CONNSTR}" "dev")

cppbessot_test_pgsql_reset_database("${_dev_connstr}")
cppbessot_test_pgsql_exec(
  "${_dev_connstr}"
  "CREATE TABLE legacy_data(id TEXT PRIMARY KEY); INSERT INTO legacy_data(id) VALUES ('old-row');")

cppbessot_test_cache_string_setting(_dev_setting "CPPBESSOT_DB_PGSQL_DEV_CONNSTR" "${_dev_connstr}")
cppbessot_test_write_project("${_case_dir}" "${_dev_setting}")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/postgre/01-schema.sql"
  "CREATE TABLE sample(id TEXT PRIMARY KEY, note TEXT);\n")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/postgre/02-seed.sql"
  "INSERT INTO sample(id, note) VALUES ('row-1', 'seeded');\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_createfrom" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_createfrom pgsql real")

cppbessot_test_pgsql_query_scalar(_row_count "${_dev_connstr}" "SELECT COUNT(*) FROM sample;")
if(NOT "${_row_count}" STREQUAL "1")
  message(FATAL_ERROR "Expected seeded sample row after PostgreSQL createfrom, got `${_row_count}`.")
endif()
cppbessot_test_pgsql_query_scalar(
  _legacy_count
  "${_dev_connstr}"
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'legacy_data';")
if(NOT "${_legacy_count}" STREQUAL "0")
  message(FATAL_ERROR "Expected legacy_data table to be removed during PostgreSQL createfrom.")
endif()

cppbessot_test_pgsql_drop_database("${_dev_connstr}")
