#pragma once

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include <gtest/gtest.h>

#include <cppbessot/model/Agent.h>

inline std::string cppbessot_required_env(const char* name)
{
  const char* value = std::getenv(name);
  if(value == nullptr || value[0] == '\0')
  {
    throw std::runtime_error(std::string("missing required environment variable: ") + name);
  }
  return value;
}

inline std::string cppbessot_env_or_default(const char* name, const char* fallback)
{
  const char* value = std::getenv(name);
  if(value != nullptr && value[0] != '\0')
  {
    return value;
  }

  if(fallback != nullptr && fallback[0] != '\0')
  {
    return fallback;
  }

  throw std::runtime_error(std::string("missing required environment variable: ") + name);
}

inline std::vector<std::filesystem::path> cppbessot_sql_files()
{
  const std::filesystem::path sql_dir(CPPBESSOT_ODB_TEST_SQL_DIR);
  if(!std::filesystem::is_directory(sql_dir))
  {
    throw std::runtime_error("SQL DDL directory does not exist: " + sql_dir.string());
  }

  std::vector<std::filesystem::path> files;
  for(const auto& entry : std::filesystem::directory_iterator(sql_dir))
  {
    if(!entry.is_regular_file() || entry.path().extension() != ".sql")
    {
      continue;
    }

    const std::string stem = entry.path().stem().string();
    if(stem.ends_with("-pre") || stem.ends_with("-post"))
    {
      // These roundtrip tests bootstrap from full schema snapshots, not ODB migration fragments.
      continue;
    }

    files.push_back(entry.path());
  }

  std::sort(files.begin(), files.end());
  if(files.empty())
  {
    throw std::runtime_error("No SQL DDL files found in " + sql_dir.string());
  }
  return files;
}

inline std::string cppbessot_read_text_file(const std::filesystem::path& path)
{
  std::ifstream stream(path);
  if(!stream)
  {
    throw std::runtime_error("Failed to open file: " + path.string());
  }

  std::ostringstream buffer;
  buffer << stream.rdbuf();
  return buffer.str();
}

template <typename Database, typename Transaction>
void cppbessot_run_agent_orm_roundtrip(Database& db)
{
  {
    Transaction t(db.begin());
    models::Agent first{};
    first.id = "agent-orm-1";
    first.role = "REQUESTER";
    first.persistent = true;
    first.displayName = "ODB Agent";
    db.persist(first);

    models::Agent second{};
    second.id = "agent-orm-2";
    second.role = "PROVIDER";
    second.persistent = false;
    second.displayName = "ODB Agent Secondary";
    db.persist(second);
    t.commit();
  }

  {
    Transaction t(db.begin());
    models::Agent loaded{};
    db.template load<models::Agent>("agent-orm-1", loaded);
    EXPECT_EQ(loaded.id, "agent-orm-1");
    EXPECT_EQ(loaded.role, "REQUESTER");
    EXPECT_TRUE(loaded.persistent);
    EXPECT_EQ(loaded.displayName, "ODB Agent");

    loaded.displayName = "ODB Agent Updated";
    db.update(loaded);
    t.commit();
  }

  {
    Transaction t(db.begin());
    using query = odb::query<models::Agent>;
    odb::result<models::Agent> results(
      db.template query<models::Agent>(query::persistent == true || query::role == "PROVIDER"));
    bool saw_updated_agent = false;
    bool saw_secondary_agent = false;
    std::size_t count = 0;
    for(const models::Agent& row : results)
    {
      ++count;
      if(row.id == "agent-orm-1")
      {
        saw_updated_agent = true;
        EXPECT_EQ(row.role, "REQUESTER");
        EXPECT_TRUE(row.persistent);
        EXPECT_EQ(row.displayName, "ODB Agent Updated");
      }
      else if(row.id == "agent-orm-2")
      {
        saw_secondary_agent = true;
        EXPECT_EQ(row.role, "PROVIDER");
        EXPECT_FALSE(row.persistent);
        EXPECT_EQ(row.displayName, "ODB Agent Secondary");
      }
      else
      {
        ADD_FAILURE() << "unexpected hydrated Agent row id: " << row.id;
      }
    }
    EXPECT_EQ(count, 2U);
    EXPECT_TRUE(saw_updated_agent);
    EXPECT_TRUE(saw_secondary_agent);

    db.template erase<models::Agent>("agent-orm-1");
    db.template erase<models::Agent>("agent-orm-2");
    t.commit();
  }

  {
    Transaction t(db.begin());
    EXPECT_FALSE(db.template find<models::Agent>("agent-orm-1"));
    EXPECT_FALSE(db.template find<models::Agent>("agent-orm-2"));
    t.commit();
  }
}
