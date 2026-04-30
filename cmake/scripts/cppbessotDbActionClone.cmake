cmake_minimum_required(VERSION 3.16)

function(cppbessot_db_action_target_exists out_var backend sqlite_path pgsql_connstr)
  if("${backend}" STREQUAL "sqlite")
    if(EXISTS "${sqlite_path}")
      set(${out_var} TRUE PARENT_SCOPE)
    else()
      set(${out_var} FALSE PARENT_SCOPE)
    endif()
    return()
  endif()

  cppbessot_db_action_find_program_or_fail(_psql psql
    "PostgreSQL live actions require `psql` to be available in PATH.")
  execute_process(
    COMMAND "${_psql}" "${pgsql_connstr}" -v ON_ERROR_STOP=1 -c "SELECT 1;"
    RESULT_VARIABLE _result
    OUTPUT_QUIET
    ERROR_QUIET
  )
  if(_result EQUAL 0)
    set(${out_var} TRUE PARENT_SCOPE)
  else()
    set(${out_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

function(cppbessot_db_action_get_clone_command out_var backend)
  if("${backend}" STREQUAL "sqlite")
    set(_command "${CPPBESSOT_DB_SQLITE_CLONE_PROD_TO_PRODDEV_COMMAND}")
  else()
    set(_command "${CPPBESSOT_DB_PGSQL_CLONE_PROD_TO_PRODDEV_COMMAND}")
  endif()
  set(${out_var} "${_command}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_invoke_clone_hook backend)
  cppbessot_db_action_get_clone_command(_clone_command "${backend}")
  if("${_clone_command}" STREQUAL "")
    message(FATAL_ERROR
      "No clone command is configured for backend `${backend}` while preparing proddev.")
  endif()

  execute_process(
    COMMAND sh -c "${_clone_command}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )

  if(NOT _result EQUAL 0)
    message(FATAL_ERROR
      "Proddev clone command failed for backend `${backend}`.\n${_stdout}\n${_stderr}")
  endif()
endfunction()

function(cppbessot_db_action_prepare_proddev target backend use_stale sqlite_path pgsql_connstr)
  if(NOT "${target}" STREQUAL "proddev")
    return()
  endif()

  if(use_stale)
    cppbessot_db_action_target_exists(_exists "${backend}" "${sqlite_path}" "${pgsql_connstr}")
    if(NOT _exists)
      message(FATAL_ERROR
        "DB_MIGRATE_PRODDEV_USE_STALE is ON, but no current stale proddev target exists.")
    endif()
    return()
  endif()

  cppbessot_db_action_invoke_clone_hook("${backend}")
  cppbessot_db_action_target_exists(_exists "${backend}" "${sqlite_path}" "${pgsql_connstr}")
  if(NOT _exists)
    message(FATAL_ERROR
      "Proddev clone command completed, but the proddev target still does not appear to exist.")
  endif()
endfunction()
