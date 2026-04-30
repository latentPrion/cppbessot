include_guard(GLOBAL)

function(_cppbessot_db_action_validate_basename value kind relative_root)
  if("${value}" STREQUAL "")
    message(FATAL_ERROR "${kind} must not be empty.")
  endif()

  if("${value}" MATCHES "[/\\\\]")
    message(FATAL_ERROR
      "${kind} `${value}` must be a basename under ${relative_root}, not a path.")
  endif()
endfunction()

function(_cppbessot_db_action_validate_db_target_impl db_target)
  if(NOT "${db_target}" STREQUAL "prod"
     AND NOT "${db_target}" STREQUAL "proddev"
     AND NOT "${db_target}" STREQUAL "dev")
    message(FATAL_ERROR "DB_TARGET must be one of: prod, proddev, dev.")
  endif()
endfunction()
