include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_DEV_PATH \"${_case_dir}/live/dev.sqlite\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_failure_contains("${_build_result}" "${_build_stderr}" "Migration directory does not exist")
