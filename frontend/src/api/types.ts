// The shapes the API sends back.
//
// Every successful response is wrapped: `{ data }` for one thing, `{ data,
// meta }` where there are counts or a currency to carry alongside the rows.
// Unwrapping happens in the hooks, so components only ever see the payload.
//
// Field names stay in the API's snake_case rather than being mapped to
// camelCase. A mapping layer is one more place for a field to go missing, and
// forms post back the same names the server validates.

export interface Envelope<T> {
  data: T
}

/** The signed-in HR Manager. There is a single role, so there is nothing else to carry. */
export interface User {
  id: number
  email_address: string
}
