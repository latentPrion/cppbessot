include_guard(GLOBAL)

if(NOT DEFINED CPPBESSOT_WORKDIR)
  set(CPPBESSOT_WORKDIR "db" CACHE STRING "CppBeSSOT schema root folder, relative to PROJECT_SOURCE_DIR or absolute path")
endif()

set(_CPPBESSOT_GENERATION_COMMON_DIR "${CMAKE_CURRENT_LIST_DIR}")

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
  get_filename_component(CPPBESSOT_CMAKE_DIR "${_CPPBESSOT_GENERATION_COMMON_DIR}" ABSOLUTE)
  get_filename_component(CPPBESSOT_MODULE_ROOT "${CPPBESSOT_CMAKE_DIR}/.." ABSOLUTE)
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

function(cppbessot_validate_schema_dir_name schema_dir)
  # Purpose: Validate that a schema directory selector is a basename, not a path.
  # Inputs:
  #   - schema_dir: Directory basename under CPPBESSOT_WORKDIR.
  # Outputs:
  #   - No return value; raises FATAL_ERROR if format is invalid.
  if("${schema_dir}" STREQUAL "")
    message(FATAL_ERROR "Schema directory name must not be empty.")
  endif()

  if("${schema_dir}" MATCHES "[/\\\\]")
    message(FATAL_ERROR
      "Schema directory name `${schema_dir}` must be a basename under CPPBESSOT_WORKDIR, not a path.")
  endif()
endfunction()

function(cppbessot_get_schema_dir_path out_var schema_dir)
  # Purpose: Resolve the absolute folder path for a specific schema directory.
  # Inputs:
  #   - out_var: Parent-scope variable name to receive the path.
  #   - schema_dir: Schema directory basename under CPPBESSOT_WORKDIR.
  # Outputs:
  #   - <out_var> (PARENT_SCOPE): Absolute `${CPPBESSOT_WORKDIR}/<schema_dir>` path.
  cppbessot_validate_schema_dir_name("${schema_dir}")
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")
  set(${out_var} "${_workdir}/${schema_dir}" PARENT_SCOPE)
endfunction()

function(cppbessot_assert_schema_dir_exists schema_dir)
  # Purpose: Assert that a schema directory exists on disk.
  # Inputs:
  #   - schema_dir: Schema directory basename.
  # Outputs:
  #   - No return value; raises FATAL_ERROR if directory is missing.
  cppbessot_get_schema_dir_path(_schema_dir_path "${schema_dir}")
  if(NOT IS_DIRECTORY "${_schema_dir_path}")
    message(FATAL_ERROR "Schema directory does not exist: ${_schema_dir_path}")
  endif()
endfunction()

function(cppbessot_get_model_headers_glob out_var schema_dir)
  # Purpose: Build a model-header glob expression for a schema directory.
  # Inputs:
  #   - out_var: Parent-scope variable name to receive the glob pattern.
  #   - schema_dir: Schema directory basename.
  # Outputs:
  #   - <out_var> (PARENT_SCOPE): Glob pattern for generated model headers.
  cppbessot_get_schema_dir_path(_schema_dir_path "${schema_dir}")
  set(${out_var} "${_schema_dir_path}/generated-cpp-source/include/*/model/*.h" PARENT_SCOPE)
endfunction()
