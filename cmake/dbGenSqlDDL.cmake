include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")
set(_CPPBESSOT_DB_GEN_SQL_DDL_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(cppbessot_add_db_gen_sql_ddl_target schema_dir)
  # Purpose: Register SQL DDL snapshot generation target for supported backends.
  # Inputs:
  #   - schema_dir: Schema directory basename to generate for.
  #   - CPPBESSOT_ODB_EXECUTABLE: Path to `odb` compiler.
  # Outputs:
  #   - CMake target: `db_gen_sql_ddl` (EXCLUDE_FROM_ALL).
  #   - Files under `<schema_dir>/generated-sql-ddl/{sqlite,postgre}`.
  cppbessot_validate_schema_dir_name("${schema_dir}")
  cppbessot_get_schema_dir_path(_version_dir "${schema_dir}")

  add_custom_target(db_gen_sql_ddl
    COMMAND "${CMAKE_COMMAND}"
            -DCPPBESSOT_ODB_EXECUTABLE=${CPPBESSOT_ODB_EXECUTABLE}
            -DCPPBESSOT_VERSION_DIR=${_version_dir}
            -P "${_CPPBESSOT_DB_GEN_SQL_DDL_DIR}/scripts/run_odb_sql_ddl.cmake"
    DEPENDS db_gen_cpp_headers
    COMMENT "Generating SQL DDL snapshots for ${schema_dir} (sqlite + postgre)"
    VERBATIM
  )

  set_target_properties(db_gen_sql_ddl PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
