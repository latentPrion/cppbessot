function(cppbessot_add_db_action_test test_name script_name)
  add_test(
    NAME ${test_name}
    COMMAND "${CMAKE_COMMAND}"
            "-DCPPBESSOT_TEST_NAME=${test_name}"
            "-DCPPBESSOT_TEST_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}"
            "-DCPPBESSOT_TEST_MODULE_SOURCE_DIR=${PROJECT_SOURCE_DIR}"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/scripts/${script_name}")
endfunction()

cppbessot_add_db_action_test(cppbessot_db_action_invalid_target invalid_target.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_mapping missing_mapping.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_ambiguous_mapping ambiguous_mapping.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_migrate_with missing_migrate_with.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_missing_migration_dir missing_migration_dir.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_proddev_createfrom_illegal proddev_createfrom_illegal.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_createfrom sqlite_createfrom.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_invalid_sql sqlite_invalid_sql.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_migrate sqlite_migrate.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_proddev_stale sqlite_proddev_stale.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_sqlite_proddev_clone sqlite_proddev_clone.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_createfrom_mock pgsql_createfrom_mock.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_migrate_order pgsql_migrate_order.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_pgsql_stale_abort pgsql_stale_abort.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_backfill_env_no_structural backfill_env_no_structural.cmake)
cppbessot_add_db_action_test(cppbessot_db_action_regression regression_targets.cmake)
