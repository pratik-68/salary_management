// The one place that talks to the API.
//
// Everything goes through `apiRequest`, so the session cookie, the JSON
// headers and the error shapes are handled once rather than in every hook.
//
// Failures arrive as an `ApiError` carrying the backend's stable `code`
// ("country_required", "invalid_credentials", ...), so callers branch on that
// rather than on prose that may be reworded later.

const BASE_PATH = '/api/v1'

/** Per-field messages from a 422, keyed by the attribute that failed. */
export type FieldErrors = Record<string, string[]>

export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly fieldErrors?: FieldErrors

  constructor(status: number, code: string, message: string, fieldErrors?: FieldErrors) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
    this.fieldErrors = fieldErrors
  }

  /** The session is missing or has ended. Watched globally, so the app can send the user back to sign in. */
  get isUnauthorized(): boolean {
    return this.status === 401
  }
}

export type QueryParams = Record<string, string | number | boolean | null | undefined>

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PATCH' | 'DELETE'
  body?: unknown
  params?: QueryParams
  signal?: AbortSignal
}

export async function apiRequest<T>(
  path: string,
  { method = 'GET', body, params, signal }: RequestOptions = {},
): Promise<T> {
  const response = await fetch(`${BASE_PATH}${path}${queryString(params)}`, {
    method,
    signal,
    // The session cookie is httpOnly and SameSite=Lax. In development the Vite
    // proxy puts the API on this same origin, so it travels exactly as it will
    // in production.
    credentials: 'same-origin',
    headers: {
      Accept: 'application/json',
      ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  const payload = await parseBody(response)

  if (!response.ok) {
    throw toApiError(response, payload)
  }

  return payload as T
}

/** A message worth showing someone, whatever went wrong. */
export function errorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message
  }

  // A network failure or a server that never answered: there is no API message
  // to pass on, so say what is actually known.
  return 'Could not reach the server. Check your connection and try again.'
}

function queryString(params?: QueryParams): string {
  if (!params) {
    return ''
  }

  const search = new URLSearchParams()

  for (const [key, value] of Object.entries(params)) {
    // A cleared filter is left out rather than sent empty: the API rejects
    // values it does not recognise, and "" is not a known department.
    if (value === undefined || value === null || value === '') {
      continue
    }

    search.set(key, String(value))
  }

  const query = search.toString()
  return query === '' ? '' : `?${query}`
}

async function parseBody(response: Response): Promise<unknown> {
  if (response.status === 204 || response.status === 205) {
    return undefined
  }

  const text = await response.text()

  if (text === '') {
    return undefined
  }

  try {
    return JSON.parse(text)
  } catch {
    // Not JSON, so something below the API answered: a proxy error page, say.
    // Keep the text rather than throwing a parse error over the real problem.
    return text
  }
}

interface ErrorPayload {
  error?: { code?: string; message?: string }
  errors?: FieldErrors
}

function toApiError(response: Response, payload: unknown): ApiError {
  const body: ErrorPayload =
    typeof payload === 'object' && payload !== null ? (payload as ErrorPayload) : {}

  // A validation failure carries per-field messages instead of one error,
  // because the form has to put each message next to the input that caused it.
  if (body.errors) {
    return new ApiError(
      response.status,
      'validation_failed',
      'Some of these details need fixing.',
      body.errors,
    )
  }

  return new ApiError(
    response.status,
    body.error?.code ?? 'unknown_error',
    body.error?.message ?? `The server responded with ${response.status}.`,
  )
}
