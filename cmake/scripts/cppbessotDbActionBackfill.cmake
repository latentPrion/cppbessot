cmake_minimum_required(VERSION 3.16)

function(cppbessot_db_action_get_hook_path out_var migration_dir hook_name)
  set(_hook_path "${migration_dir}/${hook_name}")
  if(EXISTS "${_hook_path}")
    set(${out_var} "${_hook_path}" PARENT_SCOPE)
  else()
    set(${out_var} "" PARENT_SCOPE)
  endif()
endfunction()

function(cppbessot_db_action_run_hook
    hook_path
    db_target
    backend
    migration_dir
    migrate_with
    schema_dir_to_generate
    createfrom_schema_dir
    sqlite_path
    pgsql_connstr)
  if("${hook_path}" STREQUAL "")
    return()
  endif()

  set(_env_args
    "CPPBESSOT_DB_TARGET=${db_target}"
    "CPPBESSOT_DB_BACKEND=${backend}"
    "CPPBESSOT_DB_MIGRATION_DIR=${migration_dir}"
    "CPPBESSOT_DB_MIGRATE_WITH=${migrate_with}"
    "CPPBESSOT_DB_SCHEMA_DIR_TO_GENERATE=${schema_dir_to_generate}"
    "CPPBESSOT_DB_CREATEFROM_SCHEMA_DIR=${createfrom_schema_dir}"
    "CPPBESSOT_DB_SQLITE_PATH=${sqlite_path}"
    "CPPBESSOT_DB_PGSQL_CONNSTR=${pgsql_connstr}")

  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env ${_env_args} sh "${hook_path}"
    WORKING_DIRECTORY "${migration_dir}"
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )

  if(NOT _result EQUAL 0)
    message(FATAL_ERROR
      "Backfill hook failed: ${hook_path}\n${_stdout}\n${_stderr}")
  endif()
endfunction()
