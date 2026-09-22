// The figures behind both insight views.
//
// One table serves both, because what differs between them is not the layout
// but the currency. When every row shares one, the salary columns can be
// compared: they sort, and the payroll column adds up. When the rows span
// countries they cannot, so each row carries its own currency code, sorting by
// salary is off, and the headcount is the only column with a total — it is the
// only figure with no currency attached.

import { Flex, Table, Typography } from 'antd'
import type { TableColumnsType } from 'antd'
import type { ReactNode } from 'react'
import type { BreakdownRow } from '../../api/types'
import { formatCount, formatMoney } from '../../lib/format'

/** The salary figures, in the order the HR Manager reads them. */
const SALARY_COLUMNS = [
  { key: 'min', title: 'Min' },
  { key: 'median', title: 'Median' },
  { key: 'average', title: 'Average' },
  { key: 'max', title: 'Max' },
  { key: 'total', title: 'Total payroll' },
] as const

interface Props {
  rows: BreakdownRow[]
  loading: boolean
  /** What the rows are grouped by, as the first column's heading. */
  groupLabel: string
  /** The currency every row shares, or null when the rows span countries. */
  currency: string | null
  /** How the grouped value reads, where the raw value is not it: a country code becomes its name. */
  renderGroup?: (row: BreakdownRow) => ReactNode
  emptyText?: ReactNode
}

export default function BreakdownTable({
  rows,
  loading,
  groupLabel,
  currency,
  renderGroup,
  emptyText,
}: Props) {
  const oneCurrency = currency !== null

  const columns: TableColumnsType<BreakdownRow> = [
    {
      title: groupLabel,
      dataIndex: 'group',
      key: 'group',
      // Not sortable: the API returns the catalog's own order, which for
      // levels is seniority. Alphabetical would put L10 before L2, and
      // "Director" above "Engineer".
      render: (group: string, row) => renderGroup?.(row) ?? group,
    },
    ...(oneCurrency
      ? []
      : [
          {
            title: 'Currency',
            dataIndex: 'currency',
            key: 'currency',
            width: 100,
          },
        ]),
    {
      title: 'Headcount',
      dataIndex: 'headcount',
      key: 'headcount',
      align: 'right',
      // Sortable whichever view this is: a count of people has no currency, so
      // it is the one figure that compares across countries.
      sorter: (a, b) => a.headcount - b.headcount,
    },
    ...SALARY_COLUMNS.map(({ key, title }) => ({
      title,
      dataIndex: key,
      key,
      align: 'right' as const,
      sorter: oneCurrency ? (a: BreakdownRow, b: BreakdownRow) => a[key] - b[key] : false,
      render: (amount: number, row: BreakdownRow) => formatMoney(amount, row.currency ?? ''),
    })),
  ]

  return (
    <Flex vertical gap="small">
      <Typography.Text type="secondary">
        {oneCurrency
          ? `Every figure below is in ${currency}.`
          : 'Each row is in its own currency, so the salary columns do not compare between rows and are not added up. Nothing is converted.'}
      </Typography.Text>

      <Table<BreakdownRow>
        rowKey="group"
        size="middle"
        dataSource={rows}
        columns={columns}
        loading={loading}
        pagination={false}
        scroll={{ x: 'max-content' }}
        locale={emptyText ? { emptyText } : undefined}
        // Nothing to total before the figures arrive.
        summary={rows.length === 0 ? undefined : () => <TotalsRow rows={rows} oneCurrency={oneCurrency} />}
      />
    </Flex>
  )
}

/**
 * The footer totals only what can honestly be added: the headcount always, and
 * the payroll when every row is in the same currency. Min, median, average and
 * max are left blank — an average of averages is not the average, and a median
 * cannot be recovered from medians at all.
 */
function TotalsRow({ rows, oneCurrency }: { rows: BreakdownRow[]; oneCurrency: boolean }) {
  const headcount = rows.reduce((sum, row) => sum + row.headcount, 0)
  const payroll = rows.reduce((sum, row) => sum + row.total, 0)

  // One entry per column, so the totals stay under the figures they belong to.
  // The currency column, where there is one, sits between the group and the
  // headcount and has nothing to total.
  const cells: (string | null)[] = [
    'Total',
    ...(oneCurrency ? [] : [null]),
    formatCount(headcount),
    null,
    null,
    null,
    null,
    oneCurrency ? formatMoney(payroll, rows[0].currency ?? '') : null,
  ]

  return (
    <Table.Summary.Row>
      {cells.map((cell, index) => (
        <Table.Summary.Cell key={index} index={index} align={index === 0 ? 'left' : 'right'}>
          {cell === null ? null : <Typography.Text strong>{cell}</Typography.Text>}
        </Table.Summary.Cell>
      ))}
    </Table.Summary.Row>
  )
}
