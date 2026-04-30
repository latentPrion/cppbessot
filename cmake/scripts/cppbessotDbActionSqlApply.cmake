cmake_minimum_required(VERSION 3.16)

function(cppbessot_db_action_reset_sqlite_db sqlite_path)
  if(EXISTS "${sqlite_path}")
    file(REMOVE "${sqlite_path}")
  endif()

  get_filename_component(_sqlite_parent "${sqlite_path}" DIRECTORY)
  if(NOT "${_sqlite_parent}" STREQUAL "")
    file(MAKE_DIRECTORY "${_sqlite_parent}")
  endif()
endfunction()

function(cppbessot_db_action_apply_sqlite_files sqlite_path)
  set(_sql_files "${ARGN}")
  if(NOT _sql_files)
    return()
  endif()

  cppbessot_db_action_find_program_or_fail(_sqlite3 sqlite3
    "SQLite live actions require the `sqlite3` CLI to be available in PATH.")

  foreach(_sql_file IN LISTS _sql_files)
    string(REPLACE "\"" "\\\"" _sqlite_read_file "${_sql_file}")
    execute_process(
      COMMAND "${_sqlite3}" "${sqlite_path}" ".read \"${_sqlite_read_file}\""
      RESULT_VARIABLE _result
      OUTPUT_VARIABLE _stdout
      ERROR_VARIABLE _stderr
    )

    if(NOT _result EQUAL 0)
      message(FATAL_ERROR
        "SQLite SQL apply failed for `${_sql_file}` against `${sqlite_path}`.\n${_stdout}\n${_stderr}")
    endif()
  endforeach()
endfunction()

function(cppbessot_db_action_reset_pgsql_schema pgsql_connstr)
  cppbessot_db_action_find_program_or_fail(_psql psql
    "PostgreSQL live actions require `psql` to be available in PATH.")
  execute_process(
    COMMAND "${_psql}" "${pgsql_connstr}" -v ON_ERROR_STOP=1
            -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )

  if(NOT _result EQUAL 0)
    message(FATAL_ERROR
      "PostgreSQL schema reset failed.\n${_stdout}\n${_stderr}")
  endif()
endfunction()

function(cppbessot_db_action_apply_pgsql_files pgsql_connstr)
  set(_sql_files "${ARGN}")
  if(NOT _sql_files)
    return()
  endif()

  cppbessot_db_action_find_program_or_fail(_psql psql
    "PostgreSQL live actions require `psql` to be available in PATH.")

  foreach(_sql_file IN LISTS _sql_files)
    execute_process(
      COMMAND "${_psql}" "${pgsql_connstr}" -v ON_ERROR_STOP=1 -f "${_sql_file}"
      RESULT_VARIABLE _result
      OUTPUT_VARIABLE _stdout
      ERROR_VARIABLE _stderr
    )

    if(NOT _result EQUAL 0)
      message(FATAL_ERROR
        "PostgreSQL SQL apply failed for `${_sql_file}`.\n${_stdout}\n${_stderr}")
    endif()
  endforeach()
endfunction()
