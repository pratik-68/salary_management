// Numbers and dates as the HR Manager reads them.
//
// A salary is never shown without its currency. Nothing is converted, so an
// unlabelled 90,000 sitting above an unlabelled 2,400,000 would invite exactly
// the comparison this app refuses to make.
//
// The currency appears as its code rather than its symbol: three of the eight
// countries in the catalog use "$", so a symbol alone would not say whose
// dollars these are.

// One pinned locale rather than the browser's, so the same figure reads the
// same way on every machine — including in tests, and in a screenshot pasted
// into an email.
const LOCALE = 'en-GB'

const moneyFormatters = new Map<string, Intl.NumberFormat>()

const countFormatter = new Intl.NumberFormat(LOCALE)

const compactFormatter = new Intl.NumberFormat(LOCALE, {
  notation: 'compact',
  maximumFractionDigits: 1,
})

const dateFormatter = new Intl.DateTimeFormat(LOCALE, { dateStyle: 'medium', timeZone: 'UTC' })

/** e.g. formatMoney(2_400_000, 'INR') -> "INR 2,400,000" */
export function formatMoney(amount: number, currency: string): string {
  if (currency === '') {
    // A country outside the catalog, which the API should never send. Show the
    // figure rather than nothing, but without implying a currency.
    return formatCount(amount)
  }

  return moneyFormatter(currency).format(amount)
}

export function formatCount(value: number): string {
  return countFormatter.format(value)
}

/**
 * A number short enough for a chart axis, e.g. 2_400_000 -> "2.4M".
 *
 * No currency on it: an axis repeats its labels, so the currency is named once
 * in the chart's title instead, and the tooltip and the table beside it give
 * each figure in full.
 */
export function formatCompactNumber(value: number): string {
  return compactFormatter.format(value)
}

/** An ISO date from the API, e.g. "2021-06-01" -> "1 Jun 2021". */
export function formatDate(iso: string): string {
  const [year, month, day] = iso.split('-').map(Number)

  if (!year || !month || !day) {
    return iso
  }

  // Built and read back in UTC. A hire date is a calendar day, not a moment,
  // and going through a local timezone would show the day before to anyone
  // west of UTC.
  return dateFormatter.format(new Date(Date.UTC(year, month - 1, day)))
}

function moneyFormatter(currency: string): Intl.NumberFormat {
  const cached = moneyFormatters.get(currency)

  if (cached) {
    return cached
  }

  const formatter = new Intl.NumberFormat(LOCALE, {
    style: 'currency',
    currency,
    currencyDisplay: 'code',
    // Salaries are whole units of the local currency, so cents would be noise.
    maximumFractionDigits: 0,
  })

  moneyFormatters.set(currency, formatter)
  return formatter
}
