cmake_minimum_required(VERSION 3.16)

function(cppbessot_db_action_target_upper out_var db_target)
  string(TOUPPER "${db_target}" _upper)
  set(${out_var} "${_upper}" PARENT_SCOPE)
endfunction()

function(cppbessot_db_action_resolve_backend_for_target
    out_backend
    out_sqlite_path
    out_pgsql_connstr
    db_target)
  cppbessot_db_action_validate_db_target("${db_target}")
  cppbessot_db_action_target_upper(_target_upper "${db_target}")

  set(_sqlite_var "CPPBESSOT_DB_SQLITE_${_target_upper}_PATH")
  set(_pgsql_var "CPPBESSOT_DB_PGSQL_${_target_upper}_CONNSTR")

  set(_has_sqlite FALSE)
  set(_has_pgsql FALSE)

  if(DEFINED ${_sqlite_var} AND NOT "${${_sqlite_var}}" STREQUAL "")
    set(_has_sqlite TRUE)
  endif()

  if(DEFINED ${_pgsql_var} AND NOT "${${_pgsql_var}}" STREQUAL "")
    set(_has_pgsql TRUE)
  endif()

  if(_has_sqlite AND _has_pgsql)
    message(FATAL_ERROR
      "DB target `${db_target}` is ambiguous: both `${_sqlite_var}` and `${_pgsql_var}` are set.")
  endif()

  if(NOT _has_sqlite AND NOT _has_pgsql)
    message(FATAL_ERROR
      "DB target `${db_target}` is not mapped: set exactly one of `${_sqlite_var}` or `${_pgsql_var}`.")
  endif()

  if(_has_sqlite)
    set(${out_backend} "sqlite" PARENT_SCOPE)
    set(${out_sqlite_path} "${${_sqlite_var}}" PARENT_SCOPE)
    set(${out_pgsql_connstr} "" PARENT_SCOPE)
    return()
  endif()

  set(${out_backend} "postgre" PARENT_SCOPE)
  set(${out_sqlite_path} "" PARENT_SCOPE)
  set(${out_pgsql_connstr} "${${_pgsql_var}}" PARENT_SCOPE)
endfunction()
