include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_tool_dir "${_case_dir}/tools")
set(_log_file "${_case_dir}/psql.log")
set(CPPBESSOT_TEST_LOG "${_log_file}")
cppbessot_test_write_file("${_log_file}" "")
cppbessot_test_write_mock_psql("${_tool_dir}/psql")
cppbessot_test_set_path_with_tool_dir("${_tool_dir}")
set(ENV{CPPBESSOT_TEST_LOG} "${_log_file}")
set(ENV{CPPBESSOT_TEST_PSQL_FAIL_SELECT} "1")
set(ENV{CPPBESSOT_TEST_PSQL_FAIL_ALL} "0")

cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_TARGET \"proddev\" CACHE STRING \"\")\n"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "set(DB_MIGRATE_PRODDEV_USE_STALE ON CACHE BOOL \"\")\n"
  "set(CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR \"dbname=proddev_db\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/migrations/v1.0-v1.1/postgre/01-migrate.sql"
  "ALTER TABLE sample ADD COLUMN note TEXT;\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_failure_contains("${_build_result}" "${_build_stderr}" "no current stale proddev target")
