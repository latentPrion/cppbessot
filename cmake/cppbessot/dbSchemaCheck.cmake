include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/dbGenerationCommon.cmake")

function(cppbessot_add_db_check_schema_changes_target)
  # Purpose: Register a manual target that reports git-tracked schema changes.
  # Inputs:
  #   - CPPBESSOT_WORKDIR: Schema root directory (relative or absolute).
  #   - CPPBESSOT_GIT_EXECUTABLE: Git executable path (set by dependency check).
  # Outputs:
  #   - CMake target: `db_check_schema_changes` (EXCLUDE_FROM_ALL).
  #   - Runtime warning/send-error from the script when changes are detected.
  cppbessot_abs_path(_workdir "${CPPBESSOT_WORKDIR}")

  add_custom_target(db_check_schema_changes
    COMMAND "${CMAKE_COMMAND}"
            -DCPPBESSOT_GIT_EXECUTABLE="${CPPBESSOT_GIT_EXECUTABLE}"
            -DCPPBESSOT_WORKDIR_ABS="${_workdir}"
            -DCPPBESSOT_PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/scripts/check_schema_changes.cmake"
    COMMENT "Checking for schema changes under ${CPPBESSOT_WORKDIR}"
    VERBATIM
  )

  set_target_properties(db_check_schema_changes PROPERTIES EXCLUDE_FROM_ALL TRUE)
endfunction()
