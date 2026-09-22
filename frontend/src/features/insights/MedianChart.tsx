// The medians as a picture: one bar per group, all in one currency.
//
// Bars run horizontally because the labels do — "Sales Development
// Representative" reads straight across, where a column chart would tip it on
// its side. The plot grows with the number of groups rather than squeezing
// them, so the bars keep their proportions whether there are six levels or
// twenty-six job titles.
//
// Only the median is drawn. Min, average, max and total are in the table
// beside it: five bars per group would be a wall of ink, and the median is the
// figure that answers "what do we typically pay for this?".

import { theme } from 'antd'
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import type { BreakdownRow } from '../../api/types'
import { formatCompactNumber, formatCount, formatMoney } from '../../lib/format'

/** Thin bars, with the rest of each band left as air. */
const BAR_SIZE = 20
const ROW_HEIGHT = 34

/** Room under the plot for the value axis, so it is never cut off. */
const AXIS_HEIGHT = 40

interface Props {
  rows: BreakdownRow[]
  /** The currency every row is in. The axis is bare numbers, so the title carries it. */
  currency: string
  groupLabel: string
  loading: boolean
}

export default function MedianChart({ rows, currency, groupLabel, loading }: Props) {
  const { token } = theme.useToken()

  return (
    <div
      // While the next breakdown loads, the last one stays on screen and fades
      // rather than collapsing to a spinner and jumping the page.
      style={{ opacity: loading ? 0.55 : 1, transition: 'opacity 0.2s' }}
    >
      <ResponsiveContainer width="100%" height={rows.length * ROW_HEIGHT + AXIS_HEIGHT}>
        <BarChart data={rows} layout="vertical" margin={{ top: 0, right: 24, bottom: 0, left: 0 }}>
          {/* Along the values only: a line between the bars would fence them in
              without helping anyone read a length. */}
          <CartesianGrid horizontal={false} stroke={token.colorSplit} />

          <XAxis
            type="number"
            tickFormatter={formatCompactNumber}
            tick={{ fill: token.colorTextSecondary, fontSize: 12 }}
            tickLine={false}
            axisLine={{ stroke: token.colorSplit }}
          />

          <YAxis
            type="category"
            dataKey="group"
            // Wide enough for whatever the longest label turns out to be,
            // rather than a guess that clips "People Operations Manager".
            width="auto"
            tick={{ fill: token.colorTextSecondary, fontSize: 12 }}
            tickLine={false}
            axisLine={false}
          />

          <Tooltip
            // The bar itself is the hit target, highlighted as the pointer
            // crosses it.
            cursor={{ fill: token.colorFillTertiary }}
            content={({ active, payload }) => {
              const row = payload?.[0]?.payload as BreakdownRow | undefined

              if (!active || !row) {
                return null
              }

              return (
                <div
                  style={{
                    background: token.colorBgElevated,
                    border: `1px solid ${token.colorBorderSecondary}`,
                    borderRadius: token.borderRadius,
                    boxShadow: token.boxShadowSecondary,
                    padding: '8px 12px',
                  }}
                >
                  {/* The number first: the reader already knows which bar they
                      are pointing at. */}
                  <div style={{ fontWeight: 600 }}>{formatMoney(row.median, currency)}</div>
                  <div style={{ color: token.colorTextSecondary, fontSize: 12 }}>
                    {row.group} · {headcountLabel(row.headcount)}
                  </div>
                </div>
              )
            }}
          />

          {/* One series, so one colour for every bar: shading them by size
              would spend colour saying what the lengths already say. */}
          <Bar
            dataKey="median"
            name={`Median salary (${currency})`}
            fill={token.colorPrimary}
            maxBarSize={BAR_SIZE}
            radius={[0, 4, 4, 0]}
            isAnimationActive={false}
          />
        </BarChart>
      </ResponsiveContainer>

      <div style={{ color: token.colorTextSecondary, fontSize: 12, textAlign: 'center' }}>
        Median salary by {groupLabel.toLowerCase()}, in {currency}
      </div>
    </div>
  )
}

/** A median over two people is not the same claim as one over two hundred. */
function headcountLabel(headcount: number): string {
  return `${formatCount(headcount)} ${headcount === 1 ? 'person' : 'people'}`
}
