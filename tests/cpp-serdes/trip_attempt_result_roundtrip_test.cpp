#include <gtest/gtest.h>

#include <cppbessot/model/TripAttemptResult.h>

#include "test_helpers.h"

TEST(TripAttemptResultJsonSerdes, RoundTripsViaJson)
{
  models::TripAttemptResult original{};
  original.id = "attempt-result-7";
  original.result = "failed";
  original.retryReason = "weather";
  original.governmentSuspensionReason = "";
  original.governmentTerminationReason = "";
  original.complianceSuspensionReason = "";
  original.complianceTerminationReason = "";
  original.policySuspensionReason = "";
  original.policyTerminationReason = "";
  original.cancelationReason = "";
  original.failureReason = "blocked-route";
  original.details = "bridge closure";

  const nlohmann::json expected = {
    {"id", "attempt-result-7"},
    {"result", "failed"},
    {"retryReason", "weather"},
    {"governmentSuspensionReason", ""},
    {"governmentTerminationReason", ""},
    {"complianceSuspensionReason", ""},
    {"complianceTerminationReason", ""},
    {"policySuspensionReason", ""},
    {"policyTerminationReason", ""},
    {"cancelationReason", ""},
    {"failureReason", "blocked-route"},
    {"details", "bridge closure"},
  };

  const nlohmann::json serialized = original.toJson();
  expect_json_roundtrip_equal(serialized, expected);

  const models::TripAttemptResult reparsed = models::TripAttemptResult::fromJson(serialized);
  EXPECT_EQ(reparsed.id, original.id);
  EXPECT_EQ(reparsed.result, original.result);
  EXPECT_EQ(reparsed.retryReason, original.retryReason);
  EXPECT_EQ(reparsed.governmentSuspensionReason, original.governmentSuspensionReason);
  EXPECT_EQ(reparsed.governmentTerminationReason, original.governmentTerminationReason);
  EXPECT_EQ(reparsed.complianceSuspensionReason, original.complianceSuspensionReason);
  EXPECT_EQ(reparsed.complianceTerminationReason, original.complianceTerminationReason);
  EXPECT_EQ(reparsed.policySuspensionReason, original.policySuspensionReason);
  EXPECT_EQ(reparsed.policyTerminationReason, original.policyTerminationReason);
  EXPECT_EQ(reparsed.cancelationReason, original.cancelationReason);
  EXPECT_EQ(reparsed.failureReason, original.failureReason);
  EXPECT_EQ(reparsed.details, original.details);
}
