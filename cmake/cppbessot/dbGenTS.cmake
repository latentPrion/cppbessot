include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_ts_target version)
  # Purpose: Register TypeScript type generation target from OpenAPI input.
  # Inputs:
  #   - version: Schema version to generate for.
  #   - CPPBESSOT_NPX_EXECUTABLE: Path to `npx`.
  # Outputs:
  #   - CMake target: `db_gen_ts` (EXCLUDE_FROM_ALL).
  #   - Files under `<version>/generated-ts-types`.
  cppbessot_validate_schema_version("${version}")
  cppbessot_get_version_dir(_version_dir "${version}")

  set(_openapi_file "${_version_dir}/openapi/openapi.yaml")
  set(_output_dir "${_version_dir}/generated-ts-types")

  add_custom_target(db_gen_ts
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_output_dir}"
    COMMAND "${CPPBESSOT_NPX_EXECUTABLE}" @openapitools/openapi-generator-cli generate
            -i "${_openapi_file}"
            -g typescript-fetch
            -o "${_output_dir}"
    COMMENT "Generating TypeScript types for ${version}"
    VERBATIM
  )

  set_target_properties(db_gen_ts PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
