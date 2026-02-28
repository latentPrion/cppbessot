include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")
include(CheckIncludeFileCXX)

function(_cppbessot_require_program var_name program_name hint)
  # Purpose: Locate an executable and fail with a clear install hint if missing.
  # Inputs:
  #   - var_name: Variable name to store executable path.
  #   - program_name: Program to search in PATH.
  #   - hint: Human-readable installation guidance.
  # Outputs:
  #   - <var_name>: Absolute executable path (in current scope).
  #   - No return value; raises FATAL_ERROR if program is not found.
  find_program(${var_name} ${program_name})
  if(NOT ${var_name})
    message(FATAL_ERROR
      "Missing required tool `${program_name}`. ${hint}")
  endif()
endfunction()

function(_cppbessot_require_npm_package npm_executable package_name)
  # Purpose: Ensure an npm package exists either locally in PROJECT_SOURCE_DIR
  #          or globally in the active npm installation.
  # Inputs:
  #   - npm_executable: Path to npm.
  #   - package_name: Package name to validate.
  # Outputs:
  #   - No return value; raises FATAL_ERROR when package is not installed.
  execute_process(
    COMMAND "${npm_executable}" list --depth=0 "${package_name}"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    RESULT_VARIABLE _local_result
    OUTPUT_QUIET
    ERROR_QUIET
  )

  if(NOT _local_result EQUAL 0)
    execute_process(
      COMMAND "${npm_executable}" list -g --depth=0 "${package_name}"
      RESULT_VARIABLE _global_result
      OUTPUT_QUIET
      ERROR_QUIET
    )
  else()
    set(_global_result 0)
  endif()

  if(NOT _local_result EQUAL 0 AND NOT _global_result EQUAL 0)
    message(FATAL_ERROR
      "${package_name} is not installed (not found in local or global npm packages). "
      "Install with `npm i -D ${package_name}` (project-local) or `npm i -g ${package_name}` (global).")
  endif()
endfunction()

function(_cppbessot_require_npx_package_executable npx_executable package_executable)
  # Purpose: Ensure npx can execute a package-provided executable without network
  #          resolution/download (`--no-install`).
  # Inputs:
  #   - npx_executable: Path to npx.
  #   - package_executable: Executable name exposed by a package.
  # Outputs:
  #   - No return value; raises FATAL_ERROR if execution fails.
  execute_process(
    COMMAND "${npx_executable}" --no-install "${package_executable}" --help
    RESULT_VARIABLE _help_result
    OUTPUT_QUIET
    ERROR_VARIABLE _help_stderr
  )

  if(_help_result EQUAL 0)
    return()
  endif()

  # Some CLIs return non-zero for --help; verify with version as fallback.
  execute_process(
    COMMAND "${npx_executable}" --no-install "${package_executable}" version
    RESULT_VARIABLE _version_result
    OUTPUT_QUIET
    ERROR_VARIABLE _version_stderr
  )

  if(NOT _version_result EQUAL 0)
    message(FATAL_ERROR
      "${package_executable} is not available through npx. "
      "Ensure the supplying package is installed locally or globally. "
      "Help check error: ${_help_stderr}\nVersion check error: ${_version_stderr}")
  endif()
endfunction()

function(cppbessot_check_dependencies)
  # Purpose: Validate required external tools and nlohmann/json availability.
  # Inputs:
  #   - None (uses PATH/toolchain + optional find_package results).
  # Outputs:
  #   - CPPBESSOT_ODB_EXECUTABLE (PARENT_SCOPE)
  #   - CPPBESSOT_NPX_EXECUTABLE (PARENT_SCOPE)
  #   - CPPBESSOT_NPM_EXECUTABLE (PARENT_SCOPE)
  #   - CPPBESSOT_JAVA_EXECUTABLE (PARENT_SCOPE)
  #   - CPPBESSOT_GIT_EXECUTABLE (PARENT_SCOPE)
  #   - CPPBESSOT_OPENAPI_ZOD_AVAILABLE (PARENT_SCOPE)
  #   - No return value; raises FATAL_ERROR on missing dependencies.
  _cppbessot_require_program(CPPBESSOT_ODB_EXECUTABLE odb
    "Install ODB compiler and ensure `odb` is in PATH.")
  _cppbessot_require_program(CPPBESSOT_NPX_EXECUTABLE npx
    "Install Node.js/NPM so `npx` is available.")
  _cppbessot_require_program(CPPBESSOT_NPM_EXECUTABLE npm
    "Install Node.js/NPM so `npm` is available.")
  _cppbessot_require_program(CPPBESSOT_JAVA_EXECUTABLE java
    "Install a Java runtime (OpenAPI generator uses Java).")
  _cppbessot_require_program(CPPBESSOT_GIT_EXECUTABLE git
    "Install Git and ensure it is available in PATH.")

  _cppbessot_require_npm_package("${CPPBESSOT_NPM_EXECUTABLE}" "@openapitools/openapi-generator-cli")
  _cppbessot_require_npx_package_executable("${CPPBESSOT_NPX_EXECUTABLE}" "@openapitools/openapi-generator-cli")

  _cppbessot_require_npm_package("${CPPBESSOT_NPM_EXECUTABLE}" "openapi-zod-client")
  _cppbessot_require_npx_package_executable("${CPPBESSOT_NPX_EXECUTABLE}" "openapi-zod-client")

  find_package(nlohmann_json QUIET)
  if(NOT nlohmann_json_FOUND)
    check_include_file_cxx("nlohmann/json.hpp" CPPBESSOT_HAS_NLOHMANN_JSON_HEADER)
    if(NOT CPPBESSOT_HAS_NLOHMANN_JSON_HEADER)
      message(FATAL_ERROR
        "nlohmann/json headers were not found. On Ubuntu/Debian: `sudo apt install nlohmann-json3-dev`.")
    endif()
  endif()

  set(CPPBESSOT_ODB_EXECUTABLE "${CPPBESSOT_ODB_EXECUTABLE}" PARENT_SCOPE)
  set(CPPBESSOT_NPX_EXECUTABLE "${CPPBESSOT_NPX_EXECUTABLE}" PARENT_SCOPE)
  set(CPPBESSOT_NPM_EXECUTABLE "${CPPBESSOT_NPM_EXECUTABLE}" PARENT_SCOPE)
  set(CPPBESSOT_JAVA_EXECUTABLE "${CPPBESSOT_JAVA_EXECUTABLE}" PARENT_SCOPE)
  set(CPPBESSOT_GIT_EXECUTABLE "${CPPBESSOT_GIT_EXECUTABLE}" PARENT_SCOPE)
  set(CPPBESSOT_OPENAPI_ZOD_AVAILABLE TRUE PARENT_SCOPE)
endfunction()
