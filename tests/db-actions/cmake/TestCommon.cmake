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

function(cppbessot_test_cache_string_setting out_var var_name value)
  set(${out_var} "set(${var_name} \"${value}\" CACHE STRING \"\")\n" PARENT_SCOPE)
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
  string(JOIN ";" _sql_text "${content}" ${ARGN})
  get_filename_component(_parent "${path}" DIRECTORY)
  if(NOT "${_parent}" STREQUAL "")
    file(MAKE_DIRECTORY "${_parent}")
  endif()
  file(WRITE "${path}" "${_sql_text}")
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

function(cppbessot_test_has_real_pgsql_support out_var)
  find_program(_psql psql)
  find_program(_pg_dump pg_dump)
  if(_psql AND _pg_dump AND DEFINED CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR
     AND NOT "${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" STREQUAL "")
    set(${out_var} TRUE PARENT_SCOPE)
  else()
    set(${out_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

function(cppbessot_test_require_real_pgsql_support)
  cppbessot_test_has_real_pgsql_support(_has_support)
  if(NOT _has_support)
    message(FATAL_ERROR
      "Real PostgreSQL db-action test support requires `psql`, `pg_dump`, and CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR.")
  endif()
endfunction()

function(cppbessot_test_pgsql_admin_connstr out_var)
  cppbessot_test_require_var(CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR)
  cppbessot_test_pgsql_connstr_replace_dbname(_admin_connstr "${CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR}" "postgres")
  set(${out_var} "${_admin_connstr}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_exec connstr sql_text)
  find_program(_psql psql REQUIRED)
  execute_process(
    COMMAND "${_psql}" "${connstr}" -v ON_ERROR_STOP=1 -c "${sql_text}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Failed PostgreSQL SQL execution.\n${_stdout}\n${_stderr}")
  endif()
endfunction()

function(cppbessot_test_pgsql_exec_file connstr sql_file)
  find_program(_psql psql REQUIRED)
  execute_process(
    COMMAND "${_psql}" "${connstr}" -v ON_ERROR_STOP=1 -f "${sql_file}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Failed PostgreSQL SQL file execution for `${sql_file}`.\n${_stdout}\n${_stderr}")
  endif()
endfunction()

function(cppbessot_test_pgsql_query_scalar out_var connstr query)
  find_program(_psql psql REQUIRED)
  execute_process(
    COMMAND "${_psql}" "${connstr}" -v ON_ERROR_STOP=1 -t -A -c "${query}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "Failed PostgreSQL query.\n${_stderr}")
  endif()
  string(STRIP "${_stdout}" _value)
  set(${out_var} "${_value}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_connstr_dbname out_var connstr)
  string(REGEX MATCH "(^|[ \t])dbname=([^ \t]+)" _match " ${connstr}")
  if("${CMAKE_MATCH_2}" STREQUAL "")
    message(FATAL_ERROR "Expected PostgreSQL connstr to include dbname=... but got `${connstr}`.")
  endif()
  set(${out_var} "${CMAKE_MATCH_2}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_connstr_field out_var connstr field_name)
  string(REGEX MATCH "(^|[ \t])${field_name}=([^ \t]+)" _match " ${connstr}")
  if("${CMAKE_MATCH_2}" STREQUAL "")
    message(FATAL_ERROR
      "Expected PostgreSQL connstr to include `${field_name}=...` but got `${connstr}`.")
  endif()
  set(${out_var} "${CMAKE_MATCH_2}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_connstr_replace_dbname out_var connstr new_dbname)
  cppbessot_test_pgsql_connstr_dbname(_old_dbname "${connstr}")
  string(REGEX REPLACE "(^|[ \t])dbname=[^ \t]+" "\\1dbname=${new_dbname}" _updated " ${connstr}")
  string(STRIP "${_updated}" _updated)
  set(${out_var} "${_updated}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_unique_dbname out_var role_suffix)
  cppbessot_test_require_var(CPPBESSOT_TEST_NAME)
  cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
  string(TOLOWER "${CPPBESSOT_TEST_NAME}" _base)
  string(REGEX REPLACE "[^a-z0-9]+" "_" _base "${_base}")
  string(REGEX REPLACE "^_+|_+$" "" _base "${_base}")
  if("${_base}" STREQUAL "")
    set(_base "db_action_test")
  endif()
  string(TOLOWER "${role_suffix}" _role)
  string(REGEX REPLACE "[^a-z0-9]+" "_" _role "${_role}")
  string(REGEX REPLACE "^_+|_+$" "" _role "${_role}")
  string(SHA256 _scope_hash "${CPPBESSOT_TEST_BINARY_DIR}")
  string(SUBSTRING "${_scope_hash}" 0 8 _scope_suffix)
  set(${out_var} "cppbessot_${_base}_${_role}_${_scope_suffix}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_isolated_connstr out_var base_connstr role_suffix)
  cppbessot_test_pgsql_unique_dbname(_dbname "${role_suffix}")
  cppbessot_test_pgsql_connstr_replace_dbname(_updated "${base_connstr}" "${_dbname}")
  set(${out_var} "${_updated}" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_escape_identifier out_var identifier)
  string(REPLACE "\"" "\"\"" _escaped "${identifier}")
  set(${out_var} "\"${_escaped}\"" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_escape_literal out_var literal)
  string(REPLACE "'" "''" _escaped "${literal}")
  set(${out_var} "'${_escaped}'" PARENT_SCOPE)
endfunction()

function(cppbessot_test_pgsql_drop_database connstr)
  cppbessot_test_require_real_pgsql_support()
  cppbessot_test_pgsql_admin_connstr(_admin_connstr)
  cppbessot_test_pgsql_connstr_dbname(_dbname "${connstr}")
  cppbessot_test_pgsql_escape_identifier(_db_ident "${_dbname}")
  cppbessot_test_pgsql_escape_literal(_db_lit "${_dbname}")
  cppbessot_test_pgsql_exec(
    "${_admin_connstr}"
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = ${_db_lit} AND pid <> pg_backend_pid();")
  cppbessot_test_pgsql_exec(
    "${_admin_connstr}"
    "DROP DATABASE IF EXISTS ${_db_ident};")
endfunction()

function(cppbessot_test_pgsql_create_database connstr)
  cppbessot_test_require_real_pgsql_support()
  cppbessot_test_pgsql_admin_connstr(_admin_connstr)
  cppbessot_test_pgsql_connstr_dbname(_dbname "${connstr}")
  cppbessot_test_pgsql_escape_identifier(_db_ident "${_dbname}")
  cppbessot_test_pgsql_exec(
    "${_admin_connstr}"
    "CREATE DATABASE ${_db_ident};")
endfunction()

function(cppbessot_test_pgsql_reset_database connstr)
  cppbessot_test_pgsql_drop_database("${connstr}")
  cppbessot_test_pgsql_create_database("${connstr}")
endfunction()

function(cppbessot_test_pgsql_clone_command out_var source_connstr target_connstr)
  cppbessot_test_require_real_pgsql_support()
  cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
  cppbessot_test_require_var(CPPBESSOT_TEST_NAME)
  cppbessot_test_pgsql_admin_connstr(_admin_connstr)
  cppbessot_test_pgsql_connstr_dbname(_source_db "${source_connstr}")
  cppbessot_test_pgsql_connstr_dbname(_target_db "${target_connstr}")
  cppbessot_test_pgsql_connstr_field(_admin_host "${_admin_connstr}" "host")
  cppbessot_test_pgsql_connstr_field(_admin_port "${_admin_connstr}" "port")
  cppbessot_test_pgsql_connstr_field(_admin_user "${_admin_connstr}" "user")
  cppbessot_test_pgsql_connstr_field(_admin_password "${_admin_connstr}" "password")
  cppbessot_test_pgsql_connstr_field(_source_host "${source_connstr}" "host")
  cppbessot_test_pgsql_connstr_field(_source_port "${source_connstr}" "port")
  cppbessot_test_pgsql_connstr_field(_source_user "${source_connstr}" "user")
  cppbessot_test_pgsql_connstr_field(_source_password "${source_connstr}" "password")
  cppbessot_test_pgsql_connstr_field(_target_host "${target_connstr}" "host")
  cppbessot_test_pgsql_connstr_field(_target_port "${target_connstr}" "port")
  cppbessot_test_pgsql_connstr_field(_target_user "${target_connstr}" "user")
  cppbessot_test_pgsql_connstr_field(_target_password "${target_connstr}" "password")
  set(_script_path "${CPPBESSOT_TEST_BINARY_DIR}/cases/${CPPBESSOT_TEST_NAME}/pgsql-clone.sh")
  cppbessot_test_write_shell_script(
    "${_script_path}"
    "#!/usr/bin/env bash\n"
    "set -euo pipefail\n"
    "PGPASSWORD=\"" "${_admin_password}" "\" "
    "psql -h \"" "${_admin_host}" "\" -p \"" "${_admin_port}" "\" -U \"" "${_admin_user}" "\" -d postgres -v ON_ERROR_STOP=1 -c "
    "\"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${_target_db}' AND pid <> pg_backend_pid()\"\n"
    "PGPASSWORD=\"" "${_admin_password}" "\" "
    "psql -h \"" "${_admin_host}" "\" -p \"" "${_admin_port}" "\" -U \"" "${_admin_user}" "\" -d postgres -v ON_ERROR_STOP=1 -c "
    "\"DROP DATABASE IF EXISTS ${_target_db}\"\n"
    "PGPASSWORD=\"" "${_admin_password}" "\" "
    "psql -h \"" "${_admin_host}" "\" -p \"" "${_admin_port}" "\" -U \"" "${_admin_user}" "\" -d postgres -v ON_ERROR_STOP=1 -c "
    "\"CREATE DATABASE ${_target_db} OWNER ${_target_user}\"\n"
    "PGPASSWORD=\"" "${_source_password}" "\" "
    "pg_dump -h \"" "${_source_host}" "\" -p \"" "${_source_port}" "\" -U \"" "${_source_user}" "\" -d \"" "${_source_db}" "\" --no-owner --no-privileges"
    " | "
    "PGPASSWORD=\"" "${_target_password}" "\" "
    "psql -h \"" "${_target_host}" "\" -p \"" "${_target_port}" "\" -U \"" "${_target_user}" "\" -d \"" "${_target_db}" "\" -v ON_ERROR_STOP=1\n")
  set(${out_var} "${_script_path}" PARENT_SCOPE)
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
