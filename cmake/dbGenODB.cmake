include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_odb_target version)
  # Purpose: Register ODB ORM generation target for sqlite and postgre backends.
  # Inputs:
  #   - version: Schema version to generate for.
  #   - CPPBESSOT_ODB_EXECUTABLE: Path to `odb` compiler.
  # Outputs:
  #   - CMake target: `db_gen_odb_logic` (EXCLUDE_FROM_ALL).
  #   - Files under `<version>/generated-odb-source/{sqlite,postgre}`.
  cppbessot_validate_schema_version("${version}")
  cppbessot_get_version_dir(_version_dir "${version}")

  add_custom_target(db_gen_odb_logic
    COMMAND "${CMAKE_COMMAND}"
            -DCPPBESSOT_ODB_EXECUTABLE=${CPPBESSOT_ODB_EXECUTABLE}
            -DCPPBESSOT_VERSION_DIR=${_version_dir}
            -P "${CMAKE_CURRENT_LIST_DIR}/scripts/run_odb_logic.cmake"
    DEPENDS db_gen_cpp_headers
    COMMENT "Generating ODB ORM sources for ${version} (sqlite + postgre)"
    VERBATIM
  )

  set_target_properties(db_gen_odb_logic PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
