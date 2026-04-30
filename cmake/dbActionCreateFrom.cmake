include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbActionCommon.cmake")
set(_CPPBESSOT_DB_ACTION_CREATEFROM_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(cppbessot_add_db_createfrom_target)
  _cppbessot_db_action_common_cache_args(_common_args)
  _cppbessot_add_db_action_target(
    db_createfrom
    "${_CPPBESSOT_DB_ACTION_CREATEFROM_DIR}/scripts/run_db_createfrom.cmake"
    "Creating live DB target `${DB_TARGET}` from schema `${DB_CREATEFROM_SCHEMA_DIR}`"
    ${_common_args})
endfunction()
