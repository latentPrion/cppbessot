include_guard(GLOBAL)

if(NOT DEFINED CPPBESSOT_WORKDIR)
  set(CPPBESSOT_WORKDIR "db" CACHE STRING "CppBeSSOT schema root folder, relative to PROJECT_SOURCE_DIR or absolute path")
endif()

function(cppbessot_abs_path out_var input_path)
  # Purpose: Resolve a path to an absolute path anchored at PROJECT_SOURCE_DIR
  #          when the input is relative.
  # Inputs:
  #   - out_var: Name of the parent-scope variable to write.
  #   - input_path: Relative or absolute input path.
  # Outputs:
  #   - <out_var> (PARENT_SCOPE): Absolute resolved path.
  if(IS_ABSOLUTE "${input_path}")
    set(_resolved "${input_path}")
  else()
    set(_resolved "${PROJECT_SOURCE_DIR}/${input_path}")
  endif()

  get_filename_component(_resolved "${_resolved}" ABSOLUTE)
  set(${out_var} "${_resolved}" PARENT_SCOPE)
endfunction()

function(cppbessot_initialize_paths)
  # Purpose: Initialize commonly used CppBeSSOT module and workdir paths.
  # Inputs:
  #   - CPPBESSOT_WORKDIR (cache/normal variable): Configured schema root path.
  # Outputs:
  #   - CPPBESSOT_CMAKE_DIR (PARENT_SCOPE): Absolute module directory path.
  #   - CPPBESSOT_MODULE_ROOT (PARENT_SCOPE): Module root directory path.
  #   - CPPBESSOT_WORKDIR_ABS (PARENT_SCOPE): Absolute schema root path.
  get_filename_component(CPPBESSOT_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
  get_filename_component(CPPBESSOT_MODULE_ROOT "${CPPBESSOT_CMAKE_DIR}/../.." ABSOLUTE)
  cppbessot_abs_path(CPPBESSOT_WORKDIR_ABS "${CPPBESSOT_WORKDIR}")

  set(CPPBESSOT_CMAKE_DIR "${CPPBESSOT_CMAKE_DIR}" PARENT_SCOPE)
  set(CPPBESSOT_MODULE_ROOT "${CPPBESSOT_MODULE_ROOT}" PARENT_SCOPE)
  set(CPPBESSOT_WORKDIR_ABS "${CPPBESSOT_WORKDIR_ABS}" PARENT_SCOPE)
endfunction()

function(cppbessot_require_var var_name)
  # Purpose: Fail fast if a required CMake variable is missing/empty.
  # Inputs:
  #   - var_name: Variable name to validate.
  # Outputs:
  #   - No return value; raises FATAL_ERROR on invalid input.
  if(NOT DEFINED ${var_name} OR "${${var_name}}" STREQUAL "")
    message(FATAL_ERROR "Missing required CMake variable `${var_name}`.")
  endif()
endfunction()

function(cppbessot_validate_schema_version version)
  # Purpose: Validate schema version format and enforce major >= 1.
  # Inputs:
  #   - version: Expected format `v<major>.<minor>` (e.g. v1.1).
  # Outputs:
  #   - No return value; raises FATAL_ERROR if format is invalid.
  if(NOT "${version}" MATCHES "^v([1-9][0-9]*)\\.([0-9]+)$")
    message(FATAL_ERROR
      "Invalid schema version `${version}`. Expected format `v<major>.<minor>` with major >= 1 (e.g. v1.1, v1.2).")
  endif()
endfunction()

function(cppbessot_get_version_parts version out_major out_minor)
  # Purpose: Parse schema version string into numeric major/minor components.
  # Inputs:
  #   - version: Schema version string.
  #   - out_major: Parent-scope variable name for major part.
  #   - out_minor: Parent-scope variable name for minor part.
  # Outputs:
  #   - <out_major> (PARENT_SCOPE): Major component.
  #   - <out_minor> (PARENT_SCOPE): Minor component.
  cppbessot_validate_schema_version("${version}")
  string(REGEX REPLACE "^v([1-9][0-9]*)\\.([0-9]+)$" "\\1" _major "${version}")
  string(REGEX REPLACE "^v([1-9][0-9]*)\\.([0-9]+)$" "\\2" _minor "${version}")
  set(${out_major} "${_major}" PARENT_SCOPE)
  set(${out_minor} "${_minor}" PARENT_SCOPE)
endfunction()

function(cppbessot_get_version_dir out_var version)
  # Purpose: Resolve the absolute folder path for a specific schema version.
  # Inputs:
  #   - out_var: Parent-scope variable name to receive the path.
  #   - version: Schema version string.
  # Outputs:
  #   - <out_var> (PARENT_SCOPE): Absolute `${CPPBESSOT_WORKDIR}/<version>` path.
  cppbessot_validate_schema_version("${version}")
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(${out_var} "${_workdir}/${version}" PARENT_SCOPE)
endfunction()

function(cppbessot_assert_version_dir_exists version)
  # Purpose: Assert that a schema version directory exists on disk.
  # Inputs:
  #   - version: Schema version string.
  # Outputs:
  #   - No return value; raises FATAL_ERROR if directory is missing.
  cppbessot_get_version_dir(_version_dir "${version}")
  if(NOT IS_DIRECTORY "${_version_dir}")
    message(FATAL_ERROR "Schema version folder does not exist: ${_version_dir}")
  endif()
endfunction()

function(cppbessot_get_model_headers_glob out_var version)
  # Purpose: Build a model-header glob expression for a schema version.
  # Inputs:
  #   - out_var: Parent-scope variable name to receive the glob pattern.
  #   - version: Schema version string.
  # Outputs:
  #   - <out_var> (PARENT_SCOPE): Glob pattern for generated model headers.
  cppbessot_get_version_dir(_version_dir "${version}")
  set(${out_var} "${_version_dir}/generated-cpp-source/include/*/model/*.h" PARENT_SCOPE)
endfunction()
