include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
cppbessot_test_require_var(CPPBESSOT_TEST_MODULE_SOURCE_DIR)
set(_build_dir "${CPPBESSOT_TEST_BINARY_DIR}/regression-build")
cppbessot_test_reset_dir("${_build_dir}")
get_filename_component(_repo_root "${CPPBESSOT_TEST_MODULE_SOURCE_DIR}/../.." ABSOLUTE)

execute_process(
  COMMAND "${CMAKE_COMMAND}"
          -S "${_repo_root}"
          -B "${_build_dir}"
          -DDB_SCHEMA_DIR_TO_GENERATE=v1.1
          -DDB_SCHEMA_DIR_MIGRATION_FROM=v1.1
          -DDB_SCHEMA_DIR_MIGRATION_TO=v1.2
          -DCPPBESSOT_AUTO_ENABLE=ON
  RESULT_VARIABLE _cfg_result
  OUTPUT_VARIABLE _cfg_stdout
  ERROR_VARIABLE _cfg_stderr
)
cppbessot_test_assert_success("${_cfg_result}" "${_cfg_stderr}" "fixture configure")
cppbessot_test_build_target_dry_run("${_build_dir}" "cppBeSsotOpenAiModelGen" _model_result _model_stdout _model_stderr)
cppbessot_test_assert_success("${_model_result}" "${_model_stderr}" "dry-run openai model lib build")
cppbessot_test_build_target_dry_run("${_build_dir}" "db_gen_migrations" _mig_result _mig_stdout _mig_stderr)
cppbessot_test_assert_success("${_mig_result}" "${_mig_stderr}" "dry-run migration generation build")
