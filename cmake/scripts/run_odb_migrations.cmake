cmake_minimum_required(VERSION 3.16)
include("${CMAKE_CURRENT_LIST_DIR}/cppbessotOdbHeaderDiscovery.cmake")

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

function(cppbessot_migration_resolve_backends out_var)
  if(NOT DEFINED CPPBESSOT_GEN_MIGRATION_BACKENDS OR CPPBESSOT_GEN_MIGRATION_BACKENDS STREQUAL "")
    if(DEFINED CPPBESSOT_GEN_MIGRATIONS_BACKENDS AND NOT CPPBESSOT_GEN_MIGRATIONS_BACKENDS STREQUAL "")
      set(_raw_backends "${CPPBESSOT_GEN_MIGRATIONS_BACKENDS}")
    else()
      set(_raw_backends "sqlite;pgsql")
    endif()
  else()
    set(_raw_backends "${CPPBESSOT_GEN_MIGRATION_BACKENDS}")
  endif()

  set(_resolved_backends "")
  foreach(_backend IN LISTS _raw_backends)
    string(STRIP "${_backend}" _backend)
    string(TOLOWER "${_backend}" _backend)

    if(_backend STREQUAL "")
      message(FATAL_ERROR "CPPBESSOT_GEN_MIGRATION_BACKENDS contains an empty backend name.")
    endif()

    if(NOT _backend STREQUAL "sqlite" AND NOT _backend STREQUAL "pgsql")
      message(FATAL_ERROR
        "Unsupported migration backend `${_backend}`. "
        "CPPBESSOT_GEN_MIGRATION_BACKENDS supports sqlite and pgsql.")
    endif()

    if(NOT _backend IN_LIST _resolved_backends)
      list(APPEND _resolved_backends "${_backend}")
    endif()
  endforeach()

  if(NOT _resolved_backends)
    message(FATAL_ERROR "CPPBESSOT_GEN_MIGRATION_BACKENDS must name at least one backend.")
  endif()

  set(${out_var} "${_resolved_backends}" PARENT_SCOPE)
endfunction()

function(cppbessot_migration_backend_metadata backend out_subdir out_odb_database out_database_attr)
  if("${backend}" STREQUAL "sqlite")
    set(${out_subdir} "sqlite" PARENT_SCOPE)
    set(${out_odb_database} "sqlite" PARENT_SCOPE)
    set(${out_database_attr} "sqlite" PARENT_SCOPE)
  elseif("${backend}" STREQUAL "pgsql")
    set(${out_subdir} "postgre" PARENT_SCOPE)
    set(${out_odb_database} "pgsql" PARENT_SCOPE)
    set(${out_database_attr} "pgsql" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "Unsupported migration backend `${backend}`.")
  endif()
endfunction()

function(cppbessot_migration_write_empty_changelog changelog_path database_attr)
  if(NOT EXISTS "${changelog_path}")
    file(WRITE "${changelog_path}"
"<changelog xmlns=\"http://www.codesynthesis.com/xmlns/odb/changelog\" database=\"${database_attr}\" version=\"1\">\n"
"  <model version=\"1\">\n"
"  </model>\n"
"</changelog>\n")
  endif()
endfunction()

function(cppbessot_migration_should_retry_sqlite_from_empty out_var backend from_xml empty_changelog stdout stderr)
  set(_should_retry FALSE)
  if("${backend}" STREQUAL "sqlite" AND NOT "${from_xml}" STREQUAL "${empty_changelog}")
    set(_diagnostics "${stdout}\n${stderr}")
    if(_diagnostics MATCHES "SQLite does not support dropping of columns")
      set(_should_retry TRUE)
    endif()
  endif()
  set(${out_var} "${_should_retry}" PARENT_SCOPE)
endfunction()

cppbessot_migration_resolve_backends(_migration_backends)

set(_to_include_dir "${CPPBESSOT_TO_VERSION_DIR}/generated-cpp-source/include")
cppbessot_odb_find_object_headers(_object_headers "${_to_include_dir}")

set(_empty_changelog_dir "${CPPBESSOT_MIGRATION_DIR}/.empty-baseline")
file(MAKE_DIRECTORY "${_empty_changelog_dir}")

foreach(_backend IN LISTS _migration_backends)
  cppbessot_migration_backend_metadata(
    "${_backend}"
    _subdir
    _odb_database
    _database_attr)

  set(_empty_changelog "${_empty_changelog_dir}/${_subdir}-empty.xml")
  cppbessot_migration_write_empty_changelog("${_empty_changelog}" "${_database_attr}")

  set(_migration_backend_dir "${CPPBESSOT_MIGRATION_DIR}/${_subdir}")
  file(MAKE_DIRECTORY "${_migration_backend_dir}")

  foreach(_header IN LISTS _object_headers)
    get_filename_component(_name "${_header}" NAME_WE)
    set(_in_xml "${CPPBESSOT_FROM_VERSION_DIR}/generated-odb-source/${_subdir}/${_name}.xml")
    set(_out_xml "${CPPBESSOT_TO_VERSION_DIR}/generated-odb-source/${_subdir}/${_name}.xml")

    set(_from_xml "${_in_xml}")
    if(NOT EXISTS "${_from_xml}")
      set(_from_xml "${_empty_changelog}")
    endif()

    execute_process(
      COMMAND "${CPPBESSOT_ODB_EXECUTABLE}" -I "${_to_include_dir}" --std c++11 -d "${_odb_database}"
              --generate-schema --schema-format sql -q
              -o "${_migration_backend_dir}"
              --changelog-in "${_from_xml}"
              --changelog-out "${_out_xml}"
              "${_header}"
      RESULT_VARIABLE _result
      OUTPUT_VARIABLE _stdout
      ERROR_VARIABLE _stderr
    )

    cppbessot_migration_should_retry_sqlite_from_empty(
      _retry_from_empty
      "${_backend}"
      "${_from_xml}"
      "${_empty_changelog}"
      "${_stdout}"
      "${_stderr}")

    if(NOT _result EQUAL 0 AND _retry_from_empty)
      message(WARNING
        "SQLite incremental migration failed for `${_name}`; retrying from empty baseline. "
        "Generated SQLite migration SQL is a greenfield create for this model.")
      execute_process(
        COMMAND "${CPPBESSOT_ODB_EXECUTABLE}" -I "${_to_include_dir}" --std c++11 -d "${_odb_database}"
                --generate-schema --schema-format sql -q
                -o "${_migration_backend_dir}"
                --changelog-in "${_empty_changelog}"
                --changelog-out "${_out_xml}"
                "${_header}"
        RESULT_VARIABLE _result
        OUTPUT_VARIABLE _stdout
        ERROR_VARIABLE _stderr
      )
    endif()

    if(NOT _result EQUAL 0)
      message(FATAL_ERROR
        "Migration generation failed for `${_name}` backend `${_backend}`.\n${_stdout}\n${_stderr}")
    endif()
  endforeach()
endforeach()
