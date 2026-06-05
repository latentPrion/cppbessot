include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
cppbessot_test_require_var(CPPBESSOT_TEST_MODULE_SOURCE_DIR)

set(_script_under_test "${CPPBESSOT_TEST_MODULE_SOURCE_DIR}/cmake/scripts/run_odb_migrations.cmake")

function(_cppbessot_migration_policy_fixture out_root)
  cppbessot_test_case_dir(_case_dir)
  set(_root "${_case_dir}/${ARGV1}")
  cppbessot_test_reset_dir("${_root}")
  file(MAKE_DIRECTORY
    "${_root}/from/generated-odb-source/sqlite"
    "${_root}/from/generated-odb-source/postgre"
    "${_root}/to/generated-cpp-source/include/cppbessot/model"
    "${_root}/to/generated-odb-source/sqlite"
    "${_root}/to/generated-odb-source/postgre"
    "${_root}/migrations")
  cppbessot_test_write_file(
    "${_root}/to/generated-cpp-source/include/cppbessot/model/Agent.h"
    "#pragma db object\n"
    "class Agent {};\n")
  cppbessot_test_write_file(
    "${_root}/to/generated-cpp-source/include/cppbessot/model/AgentPasswordHashType.h"
    "enum class AgentPasswordHashType { argon2id };\n")
  set(${out_root} "${_root}" PARENT_SCOPE)
endfunction()

function(_cppbessot_migration_policy_run root odb_executable result_var stdout_var stderr_var)
  set(_args
    "-DCPPBESSOT_ODB_EXECUTABLE=${odb_executable}"
    "-DCPPBESSOT_FROM_VERSION_DIR=${root}/from"
    "-DCPPBESSOT_TO_VERSION_DIR=${root}/to"
    "-DCPPBESSOT_MIGRATION_DIR=${root}/migrations")
  foreach(_extra_arg IN LISTS ARGN)
    list(APPEND _args "${_extra_arg}")
  endforeach()

  execute_process(
    COMMAND "${CMAKE_COMMAND}" ${_args} -P "${_script_under_test}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr)

  set(${result_var} "${_result}" PARENT_SCOPE)
  set(${stdout_var} "${_stdout}" PARENT_SCOPE)
  set(${stderr_var} "${_stderr}" PARENT_SCOPE)
endfunction()

function(_cppbessot_migration_policy_true_tool out_tool log_path)
  get_filename_component(_tool_dir "${log_path}" DIRECTORY)
  cppbessot_test_write_shell_script(
    "${_tool_dir}/odb-true.sh"
    "#!/usr/bin/env bash\n"
    "printf '%s\\n' \"$*\" >> \"${log_path}\"\n")
  set(${out_tool} "${_tool_dir}/odb-true.sh" PARENT_SCOPE)
endfunction()

function(_cppbessot_migration_policy_retry_tool out_tool tool_dir)
  cppbessot_test_write_shell_script(
    "${tool_dir}/odb-retry.sh"
    "#!/usr/bin/env bash\n"
    "while [[ $# -gt 0 ]]; do\n"
    "  if [[ \"$1\" == \"--changelog-in\" ]]; then\n"
    "    changelog=\"$2\"\n"
    "    shift 2\n"
    "  else\n"
    "    shift\n"
    "  fi\n"
    "done\n"
    "if [[ \"$changelog\" == *\".empty-baseline\"* ]]; then\n"
    "  exit 0\n"
    "fi\n"
    "echo \"error: SQLite does not support dropping of columns\" >&2\n"
    "exit 1\n")
  set(${out_tool} "${tool_dir}/odb-retry.sh" PARENT_SCOPE)
endfunction()

function(_cppbessot_migration_policy_false_tool out_tool tool_dir)
  cppbessot_test_write_shell_script(
    "${tool_dir}/odb-false.sh"
    "#!/usr/bin/env bash\n"
    "echo \"error: unrelated ODB failure\" >&2\n"
    "exit 1\n")
  set(${out_tool} "${tool_dir}/odb-false.sh" PARENT_SCOPE)
endfunction()

cppbessot_test_case_dir(_case_dir)
set(_configure_root "${_case_dir}/configure-policy")
set(_configure_build "${_case_dir}/configure-policy-build")
cppbessot_test_reset_dir("${_configure_root}")
cppbessot_test_write_file(
  "${_configure_root}/CMakeLists.txt"
  "cmake_minimum_required(VERSION 3.20)\n"
  "project(cppbessot_migration_policy_configure LANGUAGES CXX)\n"
  "set(CPPBESSOT_AUTO_ENABLE OFF CACHE BOOL \"\")\n"
  "include(\"${CPPBESSOT_TEST_MODULE_SOURCE_DIR}/cmake/CppBeSSOT.cmake\")\n")
execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${_configure_root}" -B "${_configure_build}"
  RESULT_VARIABLE _result
  ERROR_VARIABLE _stderr)
cppbessot_test_assert_success("${_result}" "${_stderr}" "migration backend default configure")
file(READ "${_configure_build}/CMakeCache.txt" _cache_text)
cppbessot_test_assert_contains(
  "${_cache_text}"
  "CPPBESSOT_GEN_MIGRATION_BACKENDS:STRING=sqlite;pgsql"
  "migration backend default cache")
cppbessot_test_assert_contains(
  "${_cache_text}"
  "CPPBESSOT_GEN_MIGRATIONS_BACKENDS:STRING=sqlite;pgsql"
  "migration backend alias default cache")

execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${_configure_root}" -B "${_configure_build}" -DCPPBESSOT_GEN_MIGRATION_BACKENDS=pgsql
  RESULT_VARIABLE _result
  ERROR_VARIABLE _stderr)
cppbessot_test_assert_success("${_result}" "${_stderr}" "migration backend override reconfigure")
file(READ "${_configure_build}/CMakeCache.txt" _cache_text)
cppbessot_test_assert_contains(
  "${_cache_text}"
  "CPPBESSOT_GEN_MIGRATION_BACKENDS:STRING=pgsql"
  "migration backend override cache")
cppbessot_test_assert_contains(
  "${_cache_text}"
  "CPPBESSOT_GEN_MIGRATIONS_BACKENDS:STRING=pgsql"
  "migration backend alias override cache")

_cppbessot_migration_policy_fixture(_default_root "default")
_cppbessot_migration_policy_true_tool(_true_tool "${_default_root}/odb.log")
_cppbessot_migration_policy_run("${_default_root}" "${_true_tool}" _result _stdout _stderr)
cppbessot_test_assert_success("${_result}" "${_stderr}" "default migration backend policy")
cppbessot_test_assert_file_exists("${_default_root}/migrations/sqlite")
cppbessot_test_assert_file_exists("${_default_root}/migrations/postgre")
file(READ "${_default_root}/odb.log" _default_log)
cppbessot_test_assert_contains("${_default_log}" "-d sqlite" "default backend log")
cppbessot_test_assert_contains("${_default_log}" "-d pgsql" "default backend log")
if(_default_log MATCHES "AgentPasswordHashType\\.h")
  message(FATAL_ERROR "Enum-only headers must not be passed to ODB migration generation.")
endif()

_cppbessot_migration_policy_fixture(_pgsql_root "pgsql-only")
_cppbessot_migration_policy_true_tool(_true_tool "${_pgsql_root}/odb.log")
_cppbessot_migration_policy_run(
  "${_pgsql_root}"
  "${_true_tool}"
  _result
  _stdout
  _stderr
  "-DCPPBESSOT_GEN_MIGRATION_BACKENDS=pgsql")
cppbessot_test_assert_success("${_result}" "${_stderr}" "pgsql-only migration backend policy")
cppbessot_test_assert_file_exists("${_pgsql_root}/migrations/postgre")
if(EXISTS "${_pgsql_root}/migrations/sqlite")
  message(FATAL_ERROR "pgsql-only backend selection unexpectedly created sqlite migration output.")
endif()

_cppbessot_migration_policy_fixture(_plural_root "plural-alias")
_cppbessot_migration_policy_true_tool(_true_tool "${_plural_root}/odb.log")
_cppbessot_migration_policy_run(
  "${_plural_root}"
  "${_true_tool}"
  _result
  _stdout
  _stderr
  "-DCPPBESSOT_GEN_MIGRATIONS_BACKENDS=sqlite")
cppbessot_test_assert_success("${_result}" "${_stderr}" "legacy plural backend alias policy")
cppbessot_test_assert_file_exists("${_plural_root}/migrations/sqlite")
if(EXISTS "${_plural_root}/migrations/postgre")
  message(FATAL_ERROR "plural alias sqlite-only backend selection unexpectedly created postgre migration output.")
endif()

_cppbessot_migration_policy_fixture(_invalid_root "invalid")
_cppbessot_migration_policy_run(
  "${_invalid_root}"
  "/bin/true"
  _result
  _stdout
  _stderr
  "-DCPPBESSOT_GEN_MIGRATION_BACKENDS=mysql")
cppbessot_test_assert_failure_contains("${_result}" "${_stderr}" "Unsupported migration backend")

_cppbessot_migration_policy_fixture(_retry_root "sqlite-retry")
file(WRITE "${_retry_root}/from/generated-odb-source/sqlite/Agent.xml" "")
_cppbessot_migration_policy_retry_tool(_retry_tool "${_retry_root}")
_cppbessot_migration_policy_run(
  "${_retry_root}"
  "${_retry_tool}"
  _result
  _stdout
  _stderr
  "-DCPPBESSOT_GEN_MIGRATION_BACKENDS=sqlite")
cppbessot_test_assert_success("${_result}" "${_stderr}" "sqlite drop-column retry policy")
cppbessot_test_assert_contains("${_stderr}" "SQLite incremental migration failed" "sqlite retry warning")

_cppbessot_migration_policy_fixture(_failure_root "sqlite-unrelated-failure")
file(WRITE "${_failure_root}/from/generated-odb-source/sqlite/Agent.xml" "")
_cppbessot_migration_policy_false_tool(_false_tool "${_failure_root}")
_cppbessot_migration_policy_run(
  "${_failure_root}"
  "${_false_tool}"
  _result
  _stdout
  _stderr
  "-DCPPBESSOT_GEN_MIGRATION_BACKENDS=sqlite")
cppbessot_test_assert_failure_contains("${_result}" "${_stderr}" "Migration generation failed")
