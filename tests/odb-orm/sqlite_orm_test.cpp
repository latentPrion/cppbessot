#include <odb/sqlite/database.hxx>
#include <odb/result.hxx>
#include <odb/sqlite/transaction.hxx>
#include <sqlite3.h>

#include "Agent-odb.hxx"
#include "orm_test_common.h"

namespace {

void apply_sqlite_ddl(const std::string& connstr)
{
  sqlite3* handle = nullptr;
  if(sqlite3_open(connstr.c_str(), &handle) != SQLITE_OK)
  {
    const std::string message = handle != nullptr ? sqlite3_errmsg(handle) : "sqlite open failed";
    if(handle != nullptr)
    {
      sqlite3_close(handle);
    }
    throw std::runtime_error(message);
  }

  for(const auto& sql_file : cppbessot_sql_files())
  {
    const std::string sql = cppbessot_read_text_file(sql_file);
    char* error_message = nullptr;
    const int rc = sqlite3_exec(handle, sql.c_str(), nullptr, nullptr, &error_message);
    if(rc != SQLITE_OK)
    {
      const std::string message = error_message != nullptr ? error_message : "sqlite3_exec failed";
      sqlite3_free(error_message);
      sqlite3_close(handle);
      throw std::runtime_error(message + " while applying " + sql_file.string());
    }
  }

  sqlite3_close(handle);
}

} // namespace

TEST(SqliteOdbOrm, PersistsLoadsQueriesAndErases)
{
  const std::string connstr = cppbessot_env_or_default(
    "CPPBESSOT_ODB_TEST_SQLITE_CONNSTR",
    CPPBESSOT_ODB_TEST_SQLITE_CONNSTR_DEFAULT);
  std::filesystem::remove(connstr);
  apply_sqlite_ddl(connstr);
  odb::sqlite::database db(connstr, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE);
  cppbessot_run_agent_orm_roundtrip<odb::sqlite::database, odb::sqlite::transaction>(db);
}
