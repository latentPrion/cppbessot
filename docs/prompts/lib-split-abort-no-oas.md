Ok. Let's keep the cppbessot_add_generated_libraries target, but make it actually depend on two new targets:
cppbessot_add_generated_cpp_model_libraries and cppbessot_add_generated_odb_libraries.

cppbessot_add_generated_odb_libraries adds the two cppbessot::odb_* lib targets.

The cppbessot_add_generated_cpp_model_libraries target should depend on the db_gen_cpp_headers target, and so a program that links against cppbessot::openai_model_gen should build the db_gen_cpp_headers target for the current DB_SCHEMA_DIR_TO_GENERATE first, during the build stage.

Similarly the two cppbessot::odb_* library targets should depend on the db_gen_odb_logic target, and a program that depends on that cppbessot::odb_* targets should automatically build db_gen_odb_logic target for the current DB_SCHEMA_DIR_TO_GENERATE first, at build time.

Eradicate SCHEMA_DIR completely, and leave behind only DB_SCHEMA_DIR_TO_GENERATE.

cmake configure step should fail if DB_SCHEMA_DIR_TO_GENERATE doesn't exist, or if the openapi model which it uses as its SSOT doesn't exist.
