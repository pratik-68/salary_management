// Where our people are, and what each country costs.
//
// One row per country, each in that country's own currency. There is
// deliberately no organisation-wide payroll figure: producing one would mean
// converting at a rate that moves daily, so the headline number would change
// on a day when nobody's pay had.

import { Alert } from 'antd'
import { useBreakdown } from '../../api/analytics'
import { errorMessage } from '../../api/client'
import BreakdownTable from './BreakdownTable'

export default function PayByCountry() {
  const { data, isFetching, isError, error } = useBreakdown({ group_by: 'country' })

  if (isError) {
    return (
      <Alert
        type="error"
        showIcon
        message="Couldn't load pay by country"
        description={errorMessage(error)}
      />
    )
  }

  return (
    <BreakdownTable
      rows={data?.data ?? []}
      loading={isFetching}
      groupLabel="Country"
      // The rows span countries, so each one carries its own currency.
      currency={null}
      renderGroup={(row) => row.country_name ?? row.group}
    />
  )
}
