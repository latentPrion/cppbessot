include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_migrations_target from_version to_version)
  # Purpose: Register migration SQL generation between two schema versions.
  # Inputs:
  #   - from_version: Source schema version (changelog input side).
  #   - to_version: Target schema version (header/changelog output side).
  #   - CPPBESSOT_ODB_EXECUTABLE: Path to `odb` compiler.
  # Outputs:
  #   - CMake target: `db_gen_migrations` (EXCLUDE_FROM_ALL).
  #   - Files under `migrations/<from>-<to>/{sqlite,postgre}`.
  cppbessot_validate_schema_version("${from_version}")
  cppbessot_validate_schema_version("${to_version}")

  if("${from_version}" STREQUAL "${to_version}")
    message(FATAL_ERROR "Migration `from` and `to` versions must differ.")
  endif()

  cppbessot_get_version_dir(_from_dir "${from_version}")
  cppbessot_get_version_dir(_to_dir "${to_version}")
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(_migration_dir "${_workdir}/migrations/${from_version}-${to_version}")

  add_custom_target(db_gen_migrations
    COMMAND "${CMAKE_COMMAND}"
            -DCPPBESSOT_ODB_EXECUTABLE="${CPPBESSOT_ODB_EXECUTABLE}"
            -DCPPBESSOT_FROM_VERSION_DIR="${_from_dir}"
            -DCPPBESSOT_TO_VERSION_DIR="${_to_dir}"
            -DCPPBESSOT_MIGRATION_DIR="${_migration_dir}"
            -P "${CMAKE_CURRENT_LIST_DIR}/scripts/run_odb_migrations.cmake"
    COMMENT "Generating DB migrations: ${from_version} -> ${to_version}"
    VERBATIM
  )

  set_target_properties(db_gen_migrations PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
