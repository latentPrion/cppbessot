cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED CPPBESSOT_GIT_EXECUTABLE OR CPPBESSOT_GIT_EXECUTABLE STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_GIT_EXECUTABLE is required")
endif()
if(NOT DEFINED CPPBESSOT_WORKDIR_ABS OR CPPBESSOT_WORKDIR_ABS STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_WORKDIR_ABS is required")
endif()
if(NOT DEFINED CPPBESSOT_PROJECT_SOURCE_DIR OR CPPBESSOT_PROJECT_SOURCE_DIR STREQUAL "")
  message(FATAL_ERROR "CPPBESSOT_PROJECT_SOURCE_DIR is required")
endif()

execute_process(
  COMMAND "${CPPBESSOT_GIT_EXECUTABLE}" -C "${CPPBESSOT_PROJECT_SOURCE_DIR}" rev-parse --show-toplevel
  RESULT_VARIABLE _top_result
  OUTPUT_VARIABLE _git_toplevel
  ERROR_VARIABLE _top_stderr
)

if(NOT _top_result EQUAL 0)
  message(FATAL_ERROR "git rev-parse failed while checking schema changes.\n${_top_stderr}")
endif()

string(STRIP "${_git_toplevel}" _git_toplevel)
file(RELATIVE_PATH _workdir_rel "${_git_toplevel}" "${CPPBESSOT_WORKDIR_ABS}")
if(_workdir_rel MATCHES "^\\.\\.")
  set(_workdir_rel "${CPPBESSOT_WORKDIR_ABS}")
endif()

execute_process(
  COMMAND "${CPPBESSOT_GIT_EXECUTABLE}" -C "${CPPBESSOT_PROJECT_SOURCE_DIR}" status --porcelain -- "${_workdir_rel}"
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _output
  ERROR_VARIABLE _stderr
)

if(NOT _result EQUAL 0)
  message(FATAL_ERROR "git status failed while checking schema changes.\n${_stderr}")
endif()

string(STRIP "${_output}" _output)
if(NOT _output STREQUAL "")
  if(DEFINED DB_SCHEMA_CHANGES_ARE_ERROR AND DB_SCHEMA_CHANGES_ARE_ERROR)
    message(SEND_ERROR
      "Detected changes under `${CPPBESSOT_WORKDIR_ABS}`. Create a new schema version folder and regenerate artifacts.")
  else()
    message(WARNING
      "Detected changes under `${CPPBESSOT_WORKDIR_ABS}`. Consider creating a new schema version folder and regenerating artifacts.")
  endif()
endif()
