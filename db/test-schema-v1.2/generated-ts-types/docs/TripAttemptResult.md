
# TripAttemptResult


## Properties

Name | Type
------------ | -------------
`id` | string
`result` | string
`retryReason` | string
`governmentSuspensionReason` | string
`governmentTerminationReason` | string
`complianceSuspensionReason` | string
`complianceTerminationReason` | string
`policySuspensionReason` | string
`policyTerminationReason` | string
`cancelationReason` | string
`failureReason` | string
`details` | string

## Example

```typescript
import type { TripAttemptResult } from ''

// TODO: Update the object below with actual values
const example = {
  "id": null,
  "result": null,
  "retryReason": null,
  "governmentSuspensionReason": null,
  "governmentTerminationReason": null,
  "complianceSuspensionReason": null,
  "complianceTerminationReason": null,
  "policySuspensionReason": null,
  "policyTerminationReason": null,
  "cancelationReason": null,
  "failureReason": null,
  "details": null,
} satisfies TripAttemptResult

console.log(example)

// Convert the instance to a JSON string
const exampleJSON: string = JSON.stringify(example)
console.log(exampleJSON)

// Parse the JSON string back to an object
const exampleParsed = JSON.parse(exampleJSON) as TripAttemptResult
console.log(exampleParsed)
```

[[Back to top]](#) [[Back to API list]](../README.md#api-endpoints) [[Back to Model list]](../README.md#models) [[Back to README]](../README.md)


