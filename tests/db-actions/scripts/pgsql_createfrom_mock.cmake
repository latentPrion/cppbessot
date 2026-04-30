include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_tool_dir "${_case_dir}/tools")
set(_log_file "${_case_dir}/psql.log")
set(CPPBESSOT_TEST_LOG "${_log_file}")
cppbessot_test_write_file("${_log_file}" "")
cppbessot_test_write_mock_psql("${_tool_dir}/psql")
cppbessot_test_set_path_with_tool_dir("${_tool_dir}")
set(ENV{CPPBESSOT_TEST_LOG} "${_log_file}")
set(ENV{CPPBESSOT_TEST_PSQL_FAIL_ALL} "0")
set(ENV{CPPBESSOT_TEST_PSQL_FAIL_SELECT} "0")

cppbessot_test_write_project(
  "${_case_dir}"
  "set(CPPBESSOT_DB_PGSQL_DEV_CONNSTR \"dbname=dev_db\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/postgre/01-schema.sql"
  "CREATE TABLE sample(id TEXT PRIMARY KEY);\n")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/postgre/02-seed.sql"
  "INSERT INTO sample(id) VALUES ('row-1');\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_createfrom" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_createfrom pgsql mock")

file(READ "${_log_file}" _log_contents)
cppbessot_test_assert_contains("${_log_contents}" "sqlcmd:DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;" "pgsql reset log")
cppbessot_test_assert_contains("${_log_contents}" "sqlfile:01-schema.sql" "pgsql schema log")
cppbessot_test_assert_contains("${_log_contents}" "sqlfile:02-seed.sql" "pgsql seed log")
