include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")
set(_CPPBESSOT_DB_GEN_MIGRATIONS_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(cppbessot_add_db_gen_migrations_target from_schema_dir to_schema_dir)
  # Purpose: Register migration SQL generation between two schema directories.
  # Inputs:
  #   - from_schema_dir: Source schema directory basename.
  #   - to_schema_dir: Target schema directory basename.
  #   - CPPBESSOT_ODB_EXECUTABLE: Path to `odb` compiler.
  # Outputs:
  #   - CMake target: `db_gen_migrations` (EXCLUDE_FROM_ALL).
  #   - Files under `migrations/<from>-<to>/{sqlite,postgre}`.
  cppbessot_validate_schema_dir_name("${from_schema_dir}")
  cppbessot_validate_schema_dir_name("${to_schema_dir}")

  if("${from_schema_dir}" STREQUAL "${to_schema_dir}")
    message(FATAL_ERROR "Migration `from` and `to` schema directories must differ.")
  endif()

  cppbessot_get_schema_dir_path(_from_dir "${from_schema_dir}")
  cppbessot_get_schema_dir_path(_to_dir "${to_schema_dir}")
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(_migration_dir "${_workdir}/migrations/${from_schema_dir}-${to_schema_dir}")

  add_custom_target(db_gen_migrations
    COMMAND "${CMAKE_COMMAND}"
            -DCPPBESSOT_ODB_EXECUTABLE=${CPPBESSOT_ODB_EXECUTABLE}
            -DCPPBESSOT_FROM_VERSION_DIR=${_from_dir}
            -DCPPBESSOT_TO_VERSION_DIR=${_to_dir}
            -DCPPBESSOT_MIGRATION_DIR=${_migration_dir}
            -P "${_CPPBESSOT_DB_GEN_MIGRATIONS_DIR}/scripts/run_odb_migrations.cmake"
    COMMENT "Generating DB migrations: ${from_schema_dir} -> ${to_schema_dir}"
    VERBATIM
  )

  set_target_properties(db_gen_migrations PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
