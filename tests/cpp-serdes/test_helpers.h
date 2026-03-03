#pragma once

#include <gtest/gtest.h>
#include <nlohmann/json.hpp>

inline void expect_json_roundtrip_equal(const nlohmann::json& actual, const nlohmann::json& expected)
{
  EXPECT_EQ(actual, expected) << "expected: " << expected.dump() << "\nactual: " << actual.dump();
}
