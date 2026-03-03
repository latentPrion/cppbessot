include(GoogleTest)

set(CPP_SERDES_TEST_NAME "cpp_serdes_${DB_SCHEMA_DIR_TO_GENERATE}")
string(REPLACE "." "_" CPP_SERDES_TEST_NAME "${CPP_SERDES_TEST_NAME}")
string(REPLACE "-" "_" CPP_SERDES_TEST_NAME "${CPP_SERDES_TEST_NAME}")

set(CPP_SERDES_TEST_SOURCES
  main.cpp
  government_address_roundtrip_test.cpp
  trip_attempt_result_roundtrip_test.cpp
)

add_executable(${CPP_SERDES_TEST_NAME} ${CPP_SERDES_TEST_SOURCES})
target_compile_features(${CPP_SERDES_TEST_NAME} PRIVATE cxx_std_20)
target_include_directories(${CPP_SERDES_TEST_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${CPP_SERDES_TEST_NAME}
  PRIVATE
    cppbessot::openai_model_gen
    GTest::gtest_main
)
target_compile_definitions(${CPP_SERDES_TEST_NAME}
  PRIVATE
    CPP_SERDES_SCHEMA_DIR="${DB_SCHEMA_DIR_TO_GENERATE}"
)

gtest_discover_tests(${CPP_SERDES_TEST_NAME})
