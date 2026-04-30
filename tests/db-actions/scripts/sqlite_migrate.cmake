include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_db_path "${_case_dir}/live/dev.sqlite")
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_DEV_PATH \"${_db_path}\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_write_file("${_case_dir}/db/migrations/v1.0-v1.1/README.txt" "fixture\n")
cppbessot_test_add_sql_file("${_case_dir}/db/migrations/v1.0-v1.1/sqlite/01-migrate.sql"
  "ALTER TABLE sample ADD COLUMN note TEXT DEFAULT 'migrated';\n")
cppbessot_test_sqlite_exec("${_db_path}"
  "CREATE TABLE sample(id TEXT PRIMARY KEY); INSERT INTO sample(id) VALUES ('row-1');")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_migrate sqlite")
cppbessot_test_sqlite_query_scalar(_note "${_db_path}" "SELECT note FROM sample WHERE id='row-1';")
if(NOT "${_note}" STREQUAL "migrated")
  message(FATAL_ERROR "Expected migration to add note column with default value, got `${_note}`.")
endif()
