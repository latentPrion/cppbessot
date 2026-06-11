include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_gen_cpp_target schema_dir)
  # Purpose: Register C++ model generation target using checked-in templates.
  # Inputs:
  #   - schema_dir: Schema directory basename to generate for.
  #   - CPPBESSOT_NPX_EXECUTABLE: Path to `npx`.
  # Outputs:
  #   - CMake target: `db_gen_cpp_headers` (EXCLUDE_FROM_ALL).
  #   - Files under `<schema_dir>/generated-cpp-source`.
  cppbessot_validate_schema_dir_name("${schema_dir}")
  cppbessot_get_schema_dir_path(_version_dir "${schema_dir}")
  cppbessot_get_module_root(_module_root)

  set(_openapi_file "${_version_dir}/openapi/openapi.yaml")
  set(_template_dir "${_module_root}/openapi/templates/cpp-odb-json")
  set(_template_config "${_template_dir}/config.yaml")
  set(_output_dir "${_version_dir}/generated-cpp-source")
  file(GLOB_RECURSE _template_inputs CONFIGURE_DEPENDS "${_template_dir}/*")
  cppbessot_get_expected_cpp_model_outputs(
    _expected_model_headers
    _expected_model_sources
    "${schema_dir}")

  add_custom_command(
    OUTPUT ${_expected_model_headers} ${_expected_model_sources}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_output_dir}"
    COMMAND "${CPPBESSOT_NPX_EXECUTABLE}" @openapitools/openapi-generator-cli generate
            -i "${_openapi_file}"
            -g cpp-restsdk
            -t "${_template_dir}"
            -c "${_template_config}"
            -o "${_output_dir}"
            --global-property models
    DEPENDS "${_openapi_file}" ${_template_inputs}
    WORKING_DIRECTORY "${_module_root}"
    COMMENT "Generating C++ model headers/sources for ${schema_dir}"
    VERBATIM
  )

  add_custom_target(db_gen_cpp_headers
    DEPENDS ${_expected_model_headers} ${_expected_model_sources})

  set_target_properties(db_gen_cpp_headers PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
