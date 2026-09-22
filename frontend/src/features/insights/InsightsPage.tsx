// What the pay data says, in two views.

import { Typography } from 'antd'
import PayByCountry from './PayByCountry'

export default function InsightsPage() {
  return (
    <>
      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Insights
      </Typography.Title>

      <Typography.Title level={5}>Pay by country</Typography.Title>
      <PayByCountry />
    </>
  )
}
