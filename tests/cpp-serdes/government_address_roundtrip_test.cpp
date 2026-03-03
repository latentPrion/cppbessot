#include <gtest/gtest.h>

#include <cppbessot/model/GovernmentAddress.h>

#include "test_helpers.h"

TEST(GovernmentAddressJsonSerdes, RoundTripsViaJson)
{
  models::GovernmentAddress original{};
  original.id = "gov-addr-42";
  original.addressLabel = "District Office";
  original.regionLookupKey = "region-west";

  const nlohmann::json expected = {
    {"id", "gov-addr-42"},
    {"addressLabel", "District Office"},
    {"regionLookupKey", "region-west"},
  };

  const nlohmann::json serialized = original.toJson();
  expect_json_roundtrip_equal(serialized, expected);

  const models::GovernmentAddress reparsed = models::GovernmentAddress::fromJson(serialized);
  EXPECT_EQ(reparsed.id, original.id);
  EXPECT_EQ(reparsed.addressLabel, original.addressLabel);
  EXPECT_EQ(reparsed.regionLookupKey, original.regionLookupKey);
}
