// What the pay data says, in two views.
//
// Both come from the same breakdown endpoint, and both obey the same rule:
// every figure belongs to exactly one country and is shown in that country's
// currency. Which view is open is part of the URL, so a link opens on the
// question it was sent about.

import { Tabs, Typography } from 'antd'
import PayByCountry from './PayByCountry'
import WithinCountry from './WithinCountry'
import { useInsightsParams } from './useInsightsParams'
import type { InsightsView } from './useInsightsParams'

export default function InsightsPage() {
  const { params, update } = useInsightsParams()

  return (
    <>
      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Insights
      </Typography.Title>

      <Tabs
        activeKey={params.view}
        onChange={(view) => update({ view: view as InsightsView })}
        items={[
          {
            key: 'country',
            label: 'Pay by country',
            children: <PayByCountry />,
          },
          {
            key: 'within',
            label: 'Pay within a country',
            children: <WithinCountry params={params} onChange={update} />,
          },
        ]}
      />
    </>
  )
}
