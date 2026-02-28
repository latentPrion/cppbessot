cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED CPPBESSOT_ODB_EXECUTABLE OR CPPBESSOT_ODB_EXECUTABLE STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_ODB_EXECUTABLE is required")
endif()
if(NOT DEFINED CPPBESSOT_FROM_VERSION_DIR OR CPPBESSOT_FROM_VERSION_DIR STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_FROM_VERSION_DIR is required")
endif()
if(NOT DEFINED CPPBESSOT_TO_VERSION_DIR OR CPPBESSOT_TO_VERSION_DIR STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_TO_VERSION_DIR is required")
endif()
if(NOT DEFINED CPPBESSOT_MIGRATION_DIR OR CPPBESSOT_MIGRATION_DIR STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_MIGRATION_DIR is required")
endif()

set(_to_include_dir "${CPPBESSOT_TO_VERSION_DIR}/generated-cpp-source/include")
file(GLOB _to_headers "${_to_include_dir}/*/model/*.h")
if(NOT _to_headers)
  message(FATAL_ERROR "No target-version headers found under ${_to_include_dir}")
endif()

foreach(_backend IN ITEMS sqlite pgsql)
  if(_backend STREQUAL "sqlite")
    set(_subdir sqlite)
  else()
    set(_subdir postgre)
  endif()

  set(_migration_backend_dir "${CPPBESSOT_MIGRATION_DIR}/${_subdir}")
  file(MAKE_DIRECTORY "${_migration_backend_dir}")

  foreach(_header IN LISTS _to_headers)
    get_filename_component(_name "${_header}" NAME_WE)
    set(_in_xml "${CPPBESSOT_FROM_VERSION_DIR}/generated-odb-source/${_subdir}/${_name}.xml")
    set(_out_xml "${CPPBESSOT_TO_VERSION_DIR}/generated-odb-source/${_subdir}/${_name}.xml")

    if(NOT EXISTS "${_in_xml}")
      message(FATAL_ERROR "Missing changelog input for `${_name}`: ${_in_xml}")
    endif()

    execute_process(
      COMMAND "${CPPBESSOT_ODB_EXECUTABLE}" -I "${_to_include_dir}" --std c++11 -d "${_backend}"
              --generate-schema --schema-format sql -q
              -o "${_migration_backend_dir}"
              --changelog-in "${_in_xml}"
              --changelog-out "${_out_xml}"
              "${_header}"
      RESULT_VARIABLE _result
      OUTPUT_VARIABLE _stdout
      ERROR_VARIABLE _stderr
    )

    if(NOT _result EQUAL 0)
      message(FATAL_ERROR
        "Migration generation failed for `${_name}` backend `${_backend}`.\n${_stdout}\n${_stderr}")
    endif()
  endforeach()
endforeach()
