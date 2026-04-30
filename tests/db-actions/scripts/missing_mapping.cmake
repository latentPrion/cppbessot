include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
cppbessot_test_write_project("${_case_dir}" "")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_add_sql_file("${_case_dir}/db/v1.1/generated-sql-ddl/sqlite/01-schema.sql"
  "CREATE TABLE sample(id TEXT);\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_createfrom" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_failure_contains("${_build_result}" "${_build_stderr}" "is not mapped")
