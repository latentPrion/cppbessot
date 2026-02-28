# System Spec:

The system must be able to handle anonymous one-off agents initiating requests.
Persistent users can claim agents to create persistent identities in the system.
Agents are the core actor object.
Agents can have different roles associated with them. Main roles:
*

----

/* I don't know yet how to integrate govt address labels.
 * Our system shouldn't care about gov't addresses except as
 * search designators. The users think in terms of gov't addresses,
 * but we design for coords and polygons. We are trying to move
 * pkgs from one MapRegion to another.
 *
 * The user's supplied address is just a lookup designator for what we
 * internally know as a MapRegion. This model automatically gives us
 * some resilience against political addressing scheme changes, street
 * name changes, etc.
 * When a property is sold and consolidated, or split up though, that may
 * still be difficult to handle.
 */
class GovernmentAddress
{
};

----

struct MapCoordinate
{
	Longitude longitude;
	Latitude latitude;
};

MapRegion
{
	vector<MapCoordinate> coordinates;
};

----

// This is for information relevant to package delivery.
LogisticsEndpoint: MapRegion
{
	sh_ptr<Agent> owner;
};

PackageSource: LogisticsEndpoint
{
};

PackageDestination: LogisticsEndpoint
{
};

class Warehouse: PackageSource, PackageDestination
{};

----

DeliveryRequest
{
	sh_ptr<Agent> requester;
	sh_ptr<Package> package;
	sh_ptr<PackageSource> source;
	sh_ptr<PackageDestination> destination;
};

----

/* BridgedTripAttempts routes are how we link couriers together using
 * our internal logic. All requests, including those which aren't
 * actually bridged (i.e: hops.size()==1), are modeled as bridged trips.
 */

class BridgedTripPlan
{
	sh_ptr<DeliveryRequest> deliveryRequest;
	vector<sh_ptr<TripPlan>> hops;
};

BridgedTripAttempt
{
	sh_ptr<TripAttempt>
};

/* We don't have a notion of persistent "routes". We only have "TripPlans".
 * A TripPlan is a proposed path for getting a pkg from a source to a dest.
 * It has no persistent hysteretical effect on other future TripPlans.
 *
 * To whatever extent we have "routes" they are just suggested optimizations
 * for fast lookup based on criteria like crime rates, favoured couriers,
 * package loss rate, package damage rate, etc.
 */

class TripPlan
{
	sh_ptr<Agent> courier;
	sh_ptr<PackageSource> source;
	sh_ptr<PackageDestination> destination;
	sh_ptr<OptimizedRoute> optimizedRoute;
};

/*
 * When a TripAttempt is unsuccessful, we just set the TripAttempt's Result
 * appropriately
 * and then potentially spawn a new Trip object to re-attempt.
 */
class TripAttempt
{

	TripAttemptResult result;
	sh_ptr<TripPlan> tripPlan;
	HandoverRecord handoverRecord;
};

class HandoverRecord
{
	string signatureFileName;
};

class TripAttemptResult
{
	/* Gov't suspension/termination is when an agent of gov't intervenes in
	 * a pkg's delivery.
	 * Compliance suspension/termination is when we internally intervene in
	 * pkg's delivery in order to enforce government's policy.
	 * Policy suspension/termination is when we internally intervene in a
	 * pkg's delivery because it violates an internal policy of ours.
	 */
	enum Result {
		SUCCESS, RETRY, GOVT_SUSPENSION, GOVT_TERIMATION, COMPLIANCE_SUSPENSION, COMPLIANCE_TERMINATION, POLICY_SUSPENSION, POLICY_TERMINATION, CANCELED, FAILURE;
	} result;
	enum RetryReason { RETRY_WEATHER, RETRY_ROUTE_DISREPAIR, RETRY_LABOUR_STRIKE, RETRY_UNEXPECTED_DANGER } retryReason;

	enum GovernmentSuspensionReason { GOVT_SUSPENSION_AWAIT_LICENSE, GOVT_SUSPENSION_AWAIT_INSPECTION } governmentSuspensionReason;
	enum GovernmentTermination {
		GOVT_TERMINATION_UNKNOWN, GOVT_TERIMINATION_AWAIT_LICENCE_TIMEOUT, GOVT_TERMINATION_SIEZED
	} governmentTerminationReason;

	enum ComplianceSuspensionReason {
		COMPLIANCE_SUSPENSION_MISSING_DOCUMENTATION, COMPLIANCE_SUSPENSION_INSURANCE_EXPIRED,
		COMPLIANCE_SUSPENSION_SAFETY_VIOLATION, COMPLIANCE_SUSPENSION_LEGAL_CHECK_PENDING,
		COMPLIANCE_SUSPENSION_TEMPORARY_AUDIT
	} complianceSuspensionReason;
	enum ComplianceTerminationReason {
		COMPLIANCE_TERMINATION_DOCUMENTATION_FAILED, COMPLIANCE_TERMINATION_INSURANCE_INVALID,
		COMPLIANCE_TERMINATION_PERSISTENT_SAFETY_VIOLATION,
		COMPLIANCE_TERMINATION_LEGAL_NONCOMPLIANCE,
		COMPLIANCE_TERMINATION_REGULATORY_ORDER
	} complianceTerminationReason;

	enum PolicySuspensionReason {
		POLICY_SUSPENSION_VIOLATED_INTERNAL_RULE,
		POLICY_SUSPENSION_PAYMENT_ISSUE,
		POLICY_SUSPENSION_TEMPORARY_BAN,
		POLICY_SUSPENSION_FRAUD_RISK, POLICY_SUSPENSION_MANUAL_REVIEW
	} policySuspensionReason;
	enum PolicyTerminationReason {
		POLICY_TERMINATION_BLACKLISTED,
		POLICY_TERMINATION_REPEATED_POLICY_VIOLATION,
		POLICY_TERMINATION_PAYMENT_DEFAULT, POLICY_TERMINATION_FRAUD_CONFIRMED,
		POLICY_TERMINATION_MANUAL_BLOCK
	} policyTerminationReason;

	enum CancelationReason { USER_CANCELED } cancelationReason;
	enum FailureReason { FAILURE_PKG_LOST, FAILURE_PKG_STOLEN } failureReason;
	string details;
};

----

CrimeProfile
{
};

----

class Courier
{
	vector<sh_ptr<MapRegion>> reach;
};

----



Courier: A courier is not the same as an org. A multi-region courier is represented as an org with multiple member couriers. We internally model each branch/repo of a big org as an individual "courier". A courier is a region-locked agent with vehicles for moving packages.
  * MapRegion.
  *

  * ResidentialLocation.
  * WarehouseLocation.
  *
