include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_case_dir(_case_dir)
set(_log_file "${_case_dir}/events.log")
cppbessot_test_write_file("${_log_file}" "")

cppbessot_test_write_project(
  "${_case_dir}"
  "set(DB_MIGRATE_WITH \"v1.0-v1.1\" CACHE STRING \"\")\n"
  "set(CPPBESSOT_DB_SQLITE_DEV_PATH \"${_case_dir}/live/dev.sqlite\" CACHE STRING \"\")\n")
cppbessot_test_add_schema("${_case_dir}" "v1.1")
cppbessot_test_write_shell_script(
  "${_case_dir}/db/migrations/v1.0-v1.1/pre-structural-backfill.sh"
  "#!/bin/sh\n"
  "set -eu\n"
  "printf 'pre:%s:%s:%s:%s\\n' \"$CPPBESSOT_DB_TARGET\" \"$CPPBESSOT_DB_BACKEND\" \"$CPPBESSOT_DB_MIGRATE_WITH\" \"$CPPBESSOT_DB_SCHEMA_DIR_TO_GENERATE\" >> \"${_log_file}\"\n"
  "printf 'sqlite:%s\\n' \"$CPPBESSOT_DB_SQLITE_PATH\" >> \"${_log_file}\"\n")
cppbessot_test_write_shell_script(
  "${_case_dir}/db/migrations/v1.0-v1.1/post-structural-backfill.sh"
  "#!/bin/sh\n"
  "set -eu\n"
  "printf 'post:%s\\n' \"$CPPBESSOT_DB_CREATEFROM_SCHEMA_DIR\" >> \"${_log_file}\"\n")

cppbessot_test_configure_project("${_case_dir}" "${_case_dir}/build" _cfg_result _cfg_stdout _cfg_stderr)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target("${_case_dir}/build" "db_migrate" _build_result _build_stdout _build_stderr)
cppbessot_test_assert_success("${_build_result}" "${_build_stderr}" "db_migrate hook-only")
cppbessot_test_assert_log_order("${_log_file}" "pre:dev:sqlite:v1.0-v1.1:v1.1" "sqlite:${_case_dir}/live/dev.sqlite" "post:v1.1")
