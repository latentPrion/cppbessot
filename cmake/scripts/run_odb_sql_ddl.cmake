cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED CPPBESSOT_ODB_EXECUTABLE OR CPPBESSOT_ODB_EXECUTABLE STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_ODB_EXECUTABLE is required")
endif()
if(NOT DEFINED CPPBESSOT_VERSION_DIR OR CPPBESSOT_VERSION_DIR STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_VERSION_DIR is required")
endif()

set(_include_dir "${CPPBESSOT_VERSION_DIR}/generated-cpp-source/include")
file(GLOB _headers "${_include_dir}/*/model/*.h")
if(NOT _headers)
  message(FATAL_ERROR "No model headers found under ${_include_dir}")
endif()

foreach(_backend IN ITEMS sqlite pgsql)
  if(_backend STREQUAL "sqlite")
    set(_subdir sqlite)
  else()
    set(_subdir postgre)
  endif()

  set(_ddl_dir "${CPPBESSOT_VERSION_DIR}/generated-sql-ddl/${_subdir}")
  set(_changelog_dir "${CPPBESSOT_VERSION_DIR}/generated-odb-source/${_subdir}")
  file(MAKE_DIRECTORY "${_ddl_dir}")
  file(MAKE_DIRECTORY "${_changelog_dir}")

  execute_process(
    COMMAND "${CPPBESSOT_ODB_EXECUTABLE}" -I "${_include_dir}" --std c++11 -d "${_backend}"
            --generate-schema --schema-format sql -q
            -o "${_ddl_dir}" --changelog-dir "${_changelog_dir}" ${_headers}
    RESULT_VARIABLE _result
    OUTPUT_VARIABLE _stdout
    ERROR_VARIABLE _stderr
  )

  if(NOT _result EQUAL 0)
    message(FATAL_ERROR
      "ODB SQL DDL generation failed for backend `${_backend}`.\n${_stdout}\n${_stderr}")
  endif()
endforeach()
