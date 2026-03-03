#include <odb/pgsql/database.hxx>
#include <odb/result.hxx>
#include <odb/pgsql/transaction.hxx>
#include <libpq-fe.h>

#include "Agent-odb.hxx"
#include "orm_test_common.h"

namespace {

void exec_pgsql(PGconn* conn, const std::string& sql)
{
  PGresult* result = PQexec(conn, sql.c_str());
  if(result == nullptr)
  {
    throw std::runtime_error("PQexec returned null");
  }

  const ExecStatusType status = PQresultStatus(result);
  if(status != PGRES_COMMAND_OK && status != PGRES_TUPLES_OK)
  {
    const std::string message = PQerrorMessage(conn);
    PQclear(result);
    throw std::runtime_error(message);
  }

  PQclear(result);
}

void apply_pgsql_ddl(const std::string& connstr)
{
  PGconn* conn = PQconnectdb(connstr.c_str());
  if(PQstatus(conn) != CONNECTION_OK)
  {
    const std::string message = PQerrorMessage(conn);
    PQfinish(conn);
    throw std::runtime_error(message);
  }

  exec_pgsql(conn, "DROP TABLE IF EXISTS \"TripAttemptResult\" CASCADE;");
  exec_pgsql(conn, "DROP TABLE IF EXISTS \"GovernmentAddress\" CASCADE;");
  exec_pgsql(conn, "DROP TABLE IF EXISTS \"Agent\" CASCADE;");

  for(const auto& sql_file : cppbessot_sql_files())
  {
    exec_pgsql(conn, cppbessot_read_text_file(sql_file));
  }

  PQfinish(conn);
}

} // namespace

TEST(PgsqlOdbOrm, PersistsLoadsQueriesAndErases)
{
  const std::string connstr = cppbessot_env_or_default(
    "CPPBESSOT_ODB_TEST_PGSQL_CONNSTR",
    CPPBESSOT_ODB_TEST_PGSQL_CONNSTR_DEFAULT);
  apply_pgsql_ddl(connstr);
  odb::pgsql::database db(connstr);
  cppbessot_run_agent_orm_roundtrip<odb::pgsql::database, odb::pgsql::transaction>(db);
}
