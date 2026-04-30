cmake_minimum_required(VERSION 3.16)

function(cppbessot_test_require_var var_name)
  if(NOT DEFINED ${var_name} OR "${${var_name}}" STREQUAL "")
    message(FATAL_ERROR "Missing required test variable `${var_name}`.")
  endif()
endfunction()

function(cppbessot_test_reset_dir path)
  file(REMOVE_RECURSE "${path}")
  file(MAKE_DIRECTORY "${path}")
endfunction()

function(cppbessot_test_write_file path)
  get_filename_component(_parent "${path}" DIRECTORY)
  if(NOT "${_parent}" STREQUAL "")
    file(MAKE_DIRECTORY "${_parent}")
  endif()
  string(JOIN "" _content ${ARGN})
  file(WRITE "${path}" "${_content}")
endfunction()

function(cppbessot_test_write_shell_script path)
  cppbessot_test_write_file("${path}" ${ARGN})
  execute_process(COMMAND chmod +x "${path}")
endfunction()

function(cppbessot_test_case_dir out_var)
  cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
  cppbessot_test_require_var(CPPBESSOT_TEST_NAME)
  set(_case_dir "${CPPBESSOT_TEST_BINARY_DIR}/cases/${CPPBESSOT_TEST_NAME}")
  cppbessot_test_reset_dir("${_case_dir}")
  set(${out_var} "${_case_dir}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_write_project root_dir settings_text)
  cppbessot_test_require_var(CPPBESSOT_TEST_MODULE_SOURCE_DIR)
  string(REPLACE "\\" "\\\\" _module_dir "${CPPBESSOT_TEST_MODULE_SOURCE_DIR}")
  set(_settings_parts "${settings_text}" ${ARGN})
  set(_post_include_text
    "cppbessot_add_db_createfrom_target()\n"
    "cppbessot_add_db_migrate_target()\n")
  list(LENGTH _settings_parts _settings_len)
  if(_settings_len GREATER 0)
    math(EXPR _last_index "${_settings_len} - 1")
    list(GET _settings_parts "${_last_index}" _last_part)
    if("${_last_part}" STREQUAL "FULL_ENABLE")
      list(REMOVE_AT _settings_parts "${_last_index}")
      set(_post_include_text "cppbessot_enable()\n")
    endif()
  endif()
  string(JOIN "" _settings_text ${_settings_parts})
  cppbessot_test_write_file(
    "${root_dir}/CMakeLists.txt"
    "cmake_minimum_required(VERSION 3.20)\n"
    "project(cppbessot_db_action_fixture LANGUAGES CXX)\n"
    "set(CPPBESSOT_WORKDIR \"db\" CACHE STRING \"\")\n"
    "set(DB_SCHEMA_DIR_TO_GENERATE \"v1.1\" CACHE STRING \"\")\n"
    "set(CPPBESSOT_AUTO_ENABLE OFF CACHE BOOL \"\")\n"
    "${_settings_text}\n"
    "include(\"${_module_dir}/cmake/CppBeSSOT.cmake\")\n"
    "${_post_include_text}")
endfunction()

function(cppbessot_test_add_schema root_dir schema_dir)
  cppbessot_test_write_file(
    "${root_dir}/db/${schema_dir}/openapi/openapi.yaml"
    "openapi: 3.0.0\n"
    "info:\n"
    "  title: test-${schema_dir}\n"
    "  version: 1.0.0\n"
    "paths: {}\n"
    "components:\n"
    "  schemas:\n"
    "    Agent:\n"
    "      type: object\n"
    "      properties:\n"
    "        id:\n"
    "          type: string\n")
endfunction()

function(cppbessot_test_add_sql_file path content)
  cppbessot_test_write_file("${path}" "${content}")
endfunction()

function(cppbessot_test_configure_project root_dir build_dir result_var stdout_var stderr_var)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -S "${root_dir}" -B "${build_dir}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )
  set(${result_var} "${_result}" PARENT_SCOPE)
  set(${stdout_var} "${_stdout}" PARENT_SCOPE)
  set(${stderr_var} "${_stderr}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_build_target build_dir target_name result_var stdout_var stderr_var)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${build_dir}" --target "${target_name}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )
  set(${result_var} "${_result}" PARENT_SCOPE)
  set(${stdout_var} "${_stdout}" PARENT_SCOPE)
  set(${stderr_var} "${_stderr}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_build_target_dry_run build_dir target_name result_var stdout_var stderr_var)
  execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${build_dir}" --target "${target_name}" -- -n
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )
  set(${result_var} "${_result}" PARENT_SCOPE)
  set(${stdout_var} "${_stdout}" PARENT_SCOPE)
  set(${stderr_var} "${_stderr}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_assert_success result stderr context)
  if(NOT "${result}" STREQUAL "0")
    message(FATAL_ERROR "${context} unexpectedly failed.\n${stderr}")
  endif()
endfunction()

function(cppbessot_test_assert_failure_contains result stderr needle)
  if("${result}" STREQUAL "0")
    message(FATAL_ERROR "Expected failure containing `${needle}`, but command succeeded.")
  endif()
  string(FIND "${stderr}" "${needle}" _match_index)
  if(_match_index EQUAL -1)
    message(FATAL_ERROR "Expected failure containing `${needle}`.\nActual stderr:\n${stderr}")
  endif()
endfunction()

function(cppbessot_test_assert_contains haystack needle context)
  string(FIND "${haystack}" "${needle}" _match_index)
  if(_match_index EQUAL -1)
    message(FATAL_ERROR "${context}: expected to find `${needle}` in:\n${haystack}")
  endif()
endfunction()

function(cppbessot_test_assert_file_exists path)
  if(NOT EXISTS "${path}")
    message(FATAL_ERROR "Expected file to exist: ${path}")
  endif()
endfunction()

function(cppbessot_test_set_path_with_tool_dir tool_dir)
  if(DEFINED ENV{PATH} AND NOT "$ENV{PATH}" STREQUAL "")
    set(ENV{PATH} "${tool_dir}:$ENV{PATH}")
  else()
    set(ENV{PATH} "${tool_dir}")
  endif()
endfunction()

function(cppbessot_test_sqlite_exec db_path sql_text)
  find_program(_sqlite3 sqlite3 REQUIRED)
  get_filename_component(_parent "${db_path}" DIRECTORY)
  if(NOT "${_parent}" STREQUAL "")
    file(MAKE_DIRECTORY "${_parent}")
  endif()
  set(_sql_file "${CMAKE_CURRENT_BINARY_DIR}/cppbessot-test-sqlite-exec.sql")
  file(WRITE "${_sql_file}" "${sql_text}")
  string(REPLACE "\"" "\\\"" _sqlite_read_file "${_sql_file}")
  execute_process(
    COMMAND "${_sqlite3}" "${db_path}" ".read \"${_sqlite_read_file}\""
    RESULT_VARIABLE _result
    ERROR_VARIABLE _stderr
  )
  file(REMOVE "${_sql_file}")
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Failed to execute SQLite SQL.\n${_stderr}")
  endif()
endfunction()

function(cppbessot_test_sqlite_query_scalar out_var db_path query)
  find_program(_sqlite3 sqlite3 REQUIRED)
  execute_process(
    COMMAND "${_sqlite3}" -batch -noheader "${db_path}" "${query}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Failed SQLite query.\n${_stderr}")
  endif()
  set(${out_var} "${_stdout}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_write_mock_psql path)
  cppbessot_test_write_shell_script(
    "${path}"
    "#!/bin/sh\n"
    "set -eu\n"
    "log_file=\"${CPPBESSOT_TEST_LOG}\"\n"
    "conn=\"$1\"\n"
    "shift\n"
    "printf 'conn:%s\\n' \"$conn\" >> \"$log_file\"\n"
    "if [ \"\${CPPBESSOT_TEST_PSQL_FAIL_SELECT:-0}\" = \"1\" ]\n"
    "then\n"
    "  if printf '%s ' \"$@\" | grep -F \"SELECT 1\" >/dev/null 2>&1\n"
    "  then\n"
    "    echo 'simulated select failure' >&2\n"
    "    exit 1\n"
    "  fi\n"
    "fi\n"
    "if [ \"\${CPPBESSOT_TEST_PSQL_FAIL_ALL:-0}\" = \"1\" ]\n"
    "then\n"
    "  echo 'simulated psql failure' >&2\n"
    "  exit 1\n"
    "fi\n"
    "while [ \"$#\" -gt 0 ]\n"
    "do\n"
    "  if [ \"$1\" = \"-c\" ]\n"
    "  then\n"
    "      shift\n"
    "      printf 'sqlcmd:%s\\n' \"$1\" >> \"$log_file\"\n"
    "  elif [ \"$1\" = \"-f\" ]\n"
    "  then\n"
    "      shift\n"
    "      printf 'sqlfile:%s\\n' \"$(basename \"$1\")\" >> \"$log_file\"\n"
    "  fi\n"
    "  shift\n"
    "done\n")
endfunction()

function(cppbessot_test_assert_log_order log_path)
  file(READ "${log_path}" _contents)
  set(_cursor -1)
  foreach(_needle IN LISTS ARGN)
    string(FIND "${_contents}" "${_needle}" _index)
    if(_index EQUAL -1)
      message(FATAL_ERROR "Missing log entry `${_needle}`.\nLog contents:\n${_contents}")
    endif()
    if(_index LESS_EQUAL _cursor)
      message(FATAL_ERROR "Log entry `${_needle}` appeared out of order.\nLog contents:\n${_contents}")
    endif()
    set(_cursor "${_index}")
  endforeach()
endfunction()
