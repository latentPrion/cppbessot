if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/googletest/CMakeLists.txt")
  message(FATAL_ERROR
    "GoogleTest submodule is missing. Run `git submodule update --init --recursive tests/googletest` from the cppbessot repo root.")
endif()

add_subdirectory(googletest)
add_subdirectory(cpp-serdes)
add_subdirectory(odb-orm)
