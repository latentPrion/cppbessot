include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_prod_db "${_case_dir}/live/prod.sqlite")
set(_proddev_db "${_case_dir}/live/proddev.sqlite")
set(_log_file "${_case_dir}/clone.log")
cppbessot_test_sqlite_exec("${_prod_db}"
  "CREATE TABLE sample(id TEXT PRIMARY KEY); INSERT INTO sample(id) VALUES ('prod-row');")
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_TARGET \"proddev\" CACHE STRING \"\")\n"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_PROD_PATH \"${_prod_db}\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_PRODDEV_PATH \"${_proddev_db}\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND \"cp '${_prod_db}' '${_proddev_db}' && printf 'clone\\\\n' >> '${_log_file}'\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/migrations/v1.0-v1.1/sqlite/01-migrate.sql"
  "ALTER TABLE sample ADD COLUMN note TEXT DEFAULT 'cloned';\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_migrate sqlite proddev clone")
cppbessot_test_assert_file_exists("${_proddev_db}")
cppbessot_test_sqlite_query_scalar(_note "${_proddev_db}" "SELECT note FROM sample WHERE id='prod-row';")
if(NOT "${_note}" STREQUAL "cloned")
  message(FATAL_ERROR "Expected migrated proddev clone to contain note column, got `${_note}`.")
endif()
