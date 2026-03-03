if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/googletest/CMakeLists.txt")
  message(FATAL_ERROR
    "GoogleTest submodule is missing. Run `git submodule update --init --recursive tests/googletest` from the cppbessot repo root.")
endif()

add_subdirectory(googletest EXCLUDE_FROM_ALL)
add_subdirectory(cpp-serdes EXCLUDE_FROM_ALL)
