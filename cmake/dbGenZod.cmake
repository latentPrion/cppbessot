include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_zod_target version)
  # Purpose: Register Zod schema generation target from OpenAPI input.
  # Inputs:
  #   - version: Schema version to generate for.
  #   - CPPBESSOT_NPX_EXECUTABLE: Path to `npx`.
  # Outputs:
  #   - CMake target: `db_gen_zod` (EXCLUDE_FROM_ALL).
  #   - File `<version>/generated-zod/schemas.ts`.
  cppbessot_validate_schema_version("${version}")
  cppbessot_get_version_dir(_version_dir "${version}")

  set(_openapi_file "${_version_dir}/openapi/openapi.yaml")
  set(_output_dir "${_version_dir}/generated-zod")
  set(_output_file "${_output_dir}/schemas.ts")

  add_custom_target(db_gen_zod
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_output_dir}"
    COMMAND "${CPPBESSOT_NPX_EXECUTABLE}" --no-install openapi-zod-client
            "${_openapi_file}"
            --output "${_output_file}"
            --export-schemas
    COMMENT "Generating Zod schemas for ${version}"
    VERBATIM
  )

  set_target_properties(db_gen_zod PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
