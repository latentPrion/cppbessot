include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_zod_target schema_dir)
  # Purpose: Register Zod schema generation target from OpenAPI input.
  # Inputs:
  #   - schema_dir: Schema directory basename to generate for.
  #   - CPPBESSOT_NPX_EXECUTABLE: Path to `npx`.
  # Outputs:
  #   - CMake target: `db_gen_zod` (EXCLUDE_FROM_ALL).
  #   - File `<schema_dir>/generated-zod/schemas.ts`.
  cppbessot_validate_schema_dir_name("${schema_dir}")
  cppbessot_get_schema_dir_path(_version_dir "${schema_dir}")

  set(_openapi_file "${_version_dir}/openapi/openapi.yaml")
  set(_output_dir "${_version_dir}/generated-zod")
  set(_output_file "${_output_dir}/schemas.ts")
  set(_prepend_notice_script "${CMAKE_CURRENT_LIST_DIR}/scripts/prepend_cppbessot_notice.cmake")

  add_custom_target(db_gen_zod
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_output_dir}"
    COMMAND "${CPPBESSOT_NPX_EXECUTABLE}" --no-install openapi-zod-client
            "${_openapi_file}"
            --output "${_output_file}"
            --export-schemas
    COMMAND ${CMAKE_COMMAND}
            -DCPPBESSOT_TARGET_FILE="${_output_file}"
            -P "${_prepend_notice_script}"
    COMMENT "Generating Zod schemas for ${schema_dir}"
    VERBATIM
  )

  set_target_properties(db_gen_zod PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
