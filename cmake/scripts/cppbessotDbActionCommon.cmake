cmake_minimum_required(VERSION 3.16)

include("${CMAKE_CURRENT_LIST_DIR}/../dbActionShared.cmake")

function(cppbessot_db_action_require_var var_name)
  if(NOT DEFINED ${var_name} OR "${${var_name}}" STREQUAL "")
    message(FATAL_ERROR "Required variable `${var_name}` is missing.")
  endif()
endfunction()

function(cppbessot_db_action_resolve_project_path out_var input_path)
  cppbessot_db_action_require_var(CPPBESSOT_PROJECT_SOURCE_DIR)
  if(IS_ABSOLUTE "${input_path}")
    set(_resolved "${input_path}")
  else()
    set(_resolved "${CPPBESSOT_PROJECT_SOURCE_DIR}/${input_path}")
  endif()

  get_filename_component(_resolved "${_resolved}" ABSOLUTE)
  set(${out_var} "${_resolved}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_validate_schema_dir_name schema_dir)
  _cppbessot_db_action_validate_basename(
    "${schema_dir}"
    "Schema directory name"
    "CPPBESSOT_WORKDIR")
endfunction()

function(cppbessot_db_action_get_schema_dir_path out_var schema_dir)
  cppbessot_db_action_validate_schema_dir_name("${schema_dir}")
  cppbessot_db_action_resolve_project_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(${out_var} "${_workdir}/${schema_dir}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_assert_schema_dir_ready schema_dir)
  cppbessot_db_action_get_schema_dir_path(_schema_dir_path "${schema_dir}")
  if(NOT IS_DIRECTORY "${_schema_dir_path}")
    message(FATAL_ERROR "Schema directory does not exist: ${_schema_dir_path}")
  endif()

  set(_openapi_file "${_schema_dir_path}/openapi/openapi.yaml")
  if(NOT EXISTS "${_openapi_file}")
    message(FATAL_ERROR "OpenAPI file does not exist: ${_openapi_file}")
  endif()
endfunction()

function(cppbessot_db_action_validate_migration_dir_name migration_dir)
  _cppbessot_db_action_validate_basename(
    "${migration_dir}"
    "Migration directory name"
    "CPPBESSOT_WORKDIR/migrations")
endfunction()

function(cppbessot_db_action_get_migration_dir_path out_var migration_dir)
  cppbessot_db_action_validate_migration_dir_name("${migration_dir}")
  cppbessot_db_action_resolve_project_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(${out_var} "${_workdir}/migrations/${migration_dir}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_assert_migration_dir_exists migration_dir)
  cppbessot_db_action_get_migration_dir_path(_migration_dir_path "${migration_dir}")
  if(NOT IS_DIRECTORY "${_migration_dir_path}")
    message(FATAL_ERROR "Migration directory does not exist: ${_migration_dir_path}")
  endif()
endfunction()

function(cppbessot_db_action_validate_db_target db_target)
  _cppbessot_db_action_validate_db_target_impl("${db_target}")
endfunction()

function(cppbessot_db_action_backend_subdir out_var backend)
  if("${backend}" STREQUAL "sqlite")
    set(${out_var} "sqlite" PARENT_SCOPE)
    return()
  endif()

  if("${backend}" STREQUAL "postgre")
    set(${out_var} "postgre" PARENT_SCOPE)
    return()
  endif()

  message(FATAL_ERROR "Unsupported backend `${backend}`.")
endfunction()

function(cppbessot_db_action_collect_nonempty_sql_files out_var sql_dir)
  if(NOT IS_DIRECTORY "${sql_dir}")
    set(${out_var} "" PARENT_SCOPE)
    return()
  endif()

  file(GLOB _candidate_files "${sql_dir}/*.sql")
  list(SORT _candidate_files)

  set(_sql_files)
  foreach(_candidate IN LISTS _candidate_files)
    file(READ "${_candidate}" _contents)
    string(STRIP "${_contents}" _trimmed)
    if(NOT "${_trimmed}" STREQUAL "")
      list(APPEND _sql_files "${_candidate}")
    endif()
  endforeach()

  set(${out_var} "${_sql_files}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_require_nonempty_sql_dir sql_dir failure_prefix)
  cppbessot_db_action_collect_nonempty_sql_files(_sql_files "${sql_dir}")
  if(NOT _sql_files)
    message(FATAL_ERROR "${failure_prefix}: no non-empty SQL files found under ${sql_dir}")
  endif()
endfunction()

function(cppbessot_db_action_find_program_or_fail out_var program_name hint)
  find_program(_program "${program_name}")
  if(NOT _program)
    message(FATAL_ERROR "Missing required program `${program_name}`. ${hint}")
  endif()
  set(${out_var} "${_program}" PARENT_SCOPE)
endfunction()
