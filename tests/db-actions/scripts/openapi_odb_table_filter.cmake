include("${CMAKE_CURRENT_LIST_DIR}/../cmake/TestCommon.cmake")

cppbessot_test_require_var(CPPBESSOT_TEST_BINARY_DIR)
cppbessot_test_require_var(CPPBESSOT_TEST_MODULE_SOURCE_DIR)

cppbessot_test_case_dir(_case_dir)
set(_fixture_root "${_case_dir}/openapi-filter")
cppbessot_test_reset_dir("${_fixture_root}")
file(MAKE_DIRECTORY "${_fixture_root}/db/v1.test/openapi")
cppbessot_test_write_file(
  "${_fixture_root}/db/v1.test/openapi/openapi.yaml"
  "openapi: 3.0.3\n"
  "info:\n"
  "  title: cppbessot-openapi-filter-test\n"
  "  version: \"1.0.0\"\n"
  "paths: {}\n"
  "components:\n"
  "  schemas:\n"
  "    AgentPasswordHashType:\n"
  "      type: integer\n"
  "      format: int32\n"
  "      enum:\n"
  "        - 0\n"
  "    CredentialType:\n"
  "      type: integer\n"
  "      format: int32\n"
  "      enum:\n"
  "        - 0\n"
  "    Agents:\n"
  "      type: object\n"
  "      x-odbTable: Agents\n"
  "      properties:\n"
  "        id:\n"
  "          type: string\n"
  "    Roles:\n"
  "      type: object\n"
  "      x-odbTable: Roles\n"
  "      properties:\n"
  "        id:\n"
  "          type: string\n")

set(_module_cmake_dir "${CPPBESSOT_TEST_MODULE_SOURCE_DIR}/cmake")
set(PROJECT_SOURCE_DIR "${_fixture_root}")
set(CPPBESSOT_WORKDIR "db")
include("${_module_cmake_dir}/dbGenerationCommon.cmake")

cppbessot_get_openapi_schema_names(_all_schema_names "v1.test")
cppbessot_get_openapi_odb_table_schema_names(_odb_table_schema_names "v1.test")
cppbessot_get_expected_odb_outputs(
  _sqlite_odb_sources
  _pgsql_odb_sources
  "v1.test")
cppbessot_get_expected_odb_model_headers(_odb_model_headers "v1.test")
cppbessot_get_expected_odb_outputs_all(_all_odb_sources "v1.test")
cppbessot_get_expected_odb_generation_artifacts(
  _generation_model_headers
  _generation_all_odb_sources
  "v1.test")

set(_expected_all_schema_names
  AgentPasswordHashType
  CredentialType
  Agents
  Roles)
set(_expected_odb_table_schema_names
  Agents
  Roles)

function(_cppbessot_assert_same_list label actual expected)
  list(SORT actual)
  list(SORT expected)
  if(NOT "${actual}" STREQUAL "${expected}")
    message(FATAL_ERROR
      "${label} mismatch.\n"
      "  expected: ${expected}\n"
      "  actual:   ${actual}")
  endif()
endfunction()

_cppbessot_assert_same_list(
  "all schema names"
  "${_all_schema_names}"
  "${_expected_all_schema_names}")
_cppbessot_assert_same_list(
  "x-odbTable schema names"
  "${_odb_table_schema_names}"
  "${_expected_odb_table_schema_names}")
_cppbessot_assert_same_list(
  "generation artifact model headers"
  "${_generation_model_headers}"
  "${_odb_model_headers}")
_cppbessot_assert_same_list(
  "generation artifact ODB sources"
  "${_generation_all_odb_sources}"
  "${_all_odb_sources}")

list(LENGTH _sqlite_odb_sources _sqlite_count)
list(LENGTH _pgsql_odb_sources _pgsql_count)
list(LENGTH _odb_model_headers _header_count)
list(LENGTH _all_odb_sources _all_odb_count)

if(NOT _sqlite_count EQUAL 2)
  message(FATAL_ERROR
    "Expected 2 sqlite ODB sources, got ${_sqlite_count}: ${_sqlite_odb_sources}")
endif()
if(NOT _pgsql_count EQUAL 2)
  message(FATAL_ERROR
    "Expected 2 postgre ODB sources, got ${_pgsql_count}: ${_pgsql_odb_sources}")
endif()
if(NOT _header_count EQUAL 2)
  message(FATAL_ERROR
    "Expected 2 ODB model headers, got ${_header_count}: ${_odb_model_headers}")
endif()
if(NOT _all_odb_count EQUAL 4)
  message(FATAL_ERROR
    "Expected 4 combined ODB sources, got ${_all_odb_count}: ${_all_odb_sources}")
endif()

foreach(_forbidden IN ITEMS
    AgentPasswordHashType
    CredentialType)
  foreach(_backend IN ITEMS sqlite postgre)
    set(_forbidden_source
      "${_fixture_root}/db/v1.test/generated-odb-source/${_backend}/${_forbidden}-odb.cxx")
    list(FIND _all_odb_sources "${_forbidden_source}" _forbidden_index)
    if(NOT _forbidden_index EQUAL -1)
      message(FATAL_ERROR
        "Enum schema `${_forbidden}` must not produce `${_forbidden_source}`.")
    endif()
  endforeach()
endforeach()
