include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_db_path "${_case_dir}/live/tests.sqlite")
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_TARGET \"tests\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_TESTS_PATH \"${_db_path}\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/sqlite/01-schema.sql"
  "CREATE TABLE sample(id TEXT PRIMARY KEY, note TEXT);\n")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/sqlite/02-seed.sql"
  "INSERT INTO sample(id, note) VALUES ('seed-1', 'created-second');\n")
cppbessot_test_sqlite_exec("${_db_path}"
  "CREATE TABLE old_data(id TEXT); INSERT INTO old_data(id) VALUES ('legacy');")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_createfrom" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_createfrom sqlite tests")

cppbessot_test_sqlite_query_scalar(_row_count "${_db_path}" "SELECT COUNT(*) FROM sample;")
if(NOT "${_row_count}" STREQUAL "1")
  message(FATAL_ERROR "Expected seeded sample row after recreate, got `${_row_count}`.")
endif()
cppbessot_test_sqlite_query_scalar(_old_table_count "${_db_path}"
  "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='old_data';")
if(NOT "${_old_table_count}" STREQUAL "0")
  message(FATAL_ERROR "Expected old_data table to be removed during recreate.")
endif()
