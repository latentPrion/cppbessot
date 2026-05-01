include(GoogleTest)

set(CPP_ODB_TEST_NAME_SUFFIX "${DB_SCHEMA_DIR_TO_GENERATE}")
string(REPLACE "." "_" CPP_ODB_TEST_NAME_SUFFIX "${CPP_ODB_TEST_NAME_SUFFIX}")
string(REPLACE "-" "_" CPP_ODB_TEST_NAME_SUFFIX "${CPP_ODB_TEST_NAME_SUFFIX}")

function(cppbessot_add_odb_orm_test backend target_suffix connstr_var source_file link_target)
  if("${${connstr_var}}" STREQUAL "")
    message(STATUS "Skipping ${backend} ODB runtime tests because ${connstr_var} is empty.")
    return()
  endif()

  set(_target_name "cpp_odb_orm_${target_suffix}_${CPP_ODB_TEST_NAME_SUFFIX}")
  add_executable(${_target_name} "${source_file}")
  add_dependencies(${_target_name} db_gen_sql_ddl)
  target_compile_features(${_target_name} PRIVATE cxx_std_20)
  target_include_directories(${_target_name} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  target_link_libraries(${_target_name}
    PRIVATE
      cppbessot::openai_model_gen
      ${link_target}
      GTest::gtest_main)
  target_compile_definitions(${_target_name}
    PRIVATE
      CPPBESSOT_ODB_TEST_SQL_DIR="${PROJECT_SOURCE_DIR}/db/${DB_SCHEMA_DIR_TO_GENERATE}/generated-sql-ddl/${backend}"
      ${connstr_var}_DEFAULT="${${connstr_var}}")

  if("${backend}" STREQUAL "sqlite")
    target_link_libraries(${_target_name} PRIVATE "${CPPBESSOT_SQLITE_CLIENT_LIB}")
  elseif("${backend}" STREQUAL "postgre")
    target_include_directories(${_target_name} PRIVATE "${CPPBESSOT_PGSQL_INCLUDE_DIR}")
    target_link_libraries(${_target_name} PRIVATE "${CPPBESSOT_PGSQL_CLIENT_LIB}")
  endif()

  gtest_discover_tests(${_target_name}
    PROPERTIES
      ENVIRONMENT "${connstr_var}=${${connstr_var}}")
endfunction()

cppbessot_add_odb_orm_test(
  "sqlite"
  "sqlite"
  CPPBESSOT_DB_SQLITE_PRODDEV_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/sqlite_orm_test.cpp"
  cppbessot::odb_sqlite)

cppbessot_add_odb_orm_test(
  "pgsql"
  "pgsql"
  CPPBESSOT_DB_PGSQL_PRODDEV_CONNSTR
  "${CMAKE_CURRENT_SOURCE_DIR}/pgsql_orm_test.cpp"
  cppbessot::odb_pgsql)
