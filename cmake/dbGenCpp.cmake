include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_cpp_target version)
  # Purpose: Register C++ model generation target using checked-in templates.
  # Inputs:
  #   - version: Schema version to generate for.
  #   - CPPBESSOT_NPX_EXECUTABLE: Path to `npx`.
  # Outputs:
  #   - CMake target: `db_gen_cpp_headers` (EXCLUDE_FROM_ALL).
  #   - Files under `<version>/generated-cpp-source`.
  cppbessot_validate_schema_version("${version}")
  cppbessot_get_version_dir(_version_dir "${version}")

  set(_openapi_file "${_version_dir}/openapi/openapi.yaml")
  set(_template_dir "${_version_dir}/openapi/templates/cpp-odb-json")
  set(_template_config "${_template_dir}/config.yaml")
  set(_output_dir "${_version_dir}/generated-cpp-source")

  add_custom_target(db_gen_cpp_headers
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_output_dir}"
    COMMAND "${CPPBESSOT_NPX_EXECUTABLE}" @openapitools/openapi-generator-cli generate
            -i "${_openapi_file}"
            -g cpp-restsdk
            -t "${_template_dir}"
            -c "${_template_config}"
            -o "${_output_dir}"
            --global-property models
    COMMENT "Generating C++ model headers/sources for ${version}"
    VERBATIM
  )

  set_target_properties(db_gen_cpp_headers PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
