// How pay varies inside one country.
//
// A country first, always: salaries are never converted, so "the median for
// Engineering" only means something once there is a single currency behind it.
// The API refuses the question without a country, and this view does not ask
// it until one has been picked.
//
// Then a grouping — department, job title or level — and optionally a narrower
// slice of the workforce: India, by level, Software Engineers only.

import { Alert, Button, Empty, Flex, Segmented, Select, Typography } from 'antd'
import { useBreakdown } from '../../api/analytics'
import { errorMessage } from '../../api/client'
import { useReferenceData } from '../../api/meta'
import type { BreakdownRow } from '../../api/types'
import BreakdownTable from './BreakdownTable'
import MedianChart from './MedianChart'
import { GROUP_LABELS, WITHIN_GROUPS } from './useInsightsParams'
import type { InsightsParams, WithinGroupBy } from './useInsightsParams'

interface Props {
  params: InsightsParams
  onChange: (patch: Partial<InsightsParams>) => void
}

export default function WithinCountry({ params, onChange }: Props) {
  const { data: catalog } = useReferenceData()
  const { data, isFetching, isError, error } = useBreakdown(
    {
      group_by: params.group_by,
      country: params.country,
      department: params.department,
      job_title: params.job_title,
      level: params.level,
    },
    { enabled: Boolean(params.country) },
  )

  const groupLabel = GROUP_LABELS[params.group_by]
  const rows = data?.data ?? []

  // The API's answer describes the rows on screen, so it is preferred while
  // the country is being changed and the previous country's rows are still
  // showing. The catalog covers the first load, before any answer.
  const currency =
    data?.meta.currency ??
    catalog?.countries.find((country) => country.code === params.country)?.currency ??
    null

  // Once a department is chosen only its own titles are offered; without one,
  // every title is, so a title can be picked first.
  const jobTitles = params.department
    ? (catalog?.departments.find((department) => department.name === params.department)?.job_titles ?? [])
    : (catalog?.job_titles ?? [])

  const hasFilters = Boolean(params.department || params.job_title || params.level)

  return (
    <Flex vertical gap="middle">
      {/* One row of controls above everything they scope, so the table and the
          chart always show the same slice. */}
      <Flex wrap gap="small" align="center">
        <Select
          showSearch
          optionFilterProp="label"
          placeholder="Choose a country"
          style={{ minWidth: 220 }}
          value={params.country}
          onChange={(country: string) => onChange({ country })}
          options={(catalog?.countries ?? []).map((country) => ({
            value: country.code,
            label: `${country.name} (${country.currency})`,
          }))}
        />

        <Segmented<WithinGroupBy>
          value={params.group_by}
          onChange={(groupBy) => onChange({ group_by: groupBy })}
          options={WITHIN_GROUPS.map((group) => ({ value: group, label: GROUP_LABELS[group] }))}
        />

        <Select
          allowClear
          showSearch
          optionFilterProp="label"
          placeholder="Department"
          style={{ minWidth: 180 }}
          value={params.department}
          // A title from the old department would match nobody.
          onChange={(department?: string) => onChange({ department, job_title: undefined })}
          options={(catalog?.departments ?? []).map((department) => ({
            value: department.name,
            label: department.name,
          }))}
        />

        <Select
          allowClear
          showSearch
          optionFilterProp="label"
          placeholder="Job title"
          style={{ minWidth: 220 }}
          value={params.job_title}
          onChange={(jobTitle?: string) => onChange({ job_title: jobTitle })}
          options={jobTitles.map((title) => ({ value: title, label: title }))}
        />

        <Select
          allowClear
          placeholder="Level"
          style={{ minWidth: 110 }}
          value={params.level}
          onChange={(level?: string) => onChange({ level })}
          options={(catalog?.levels ?? []).map((level) => ({ value: level, label: level }))}
        />

        {hasFilters && (
          <Button
            type="link"
            onClick={() =>
              onChange({ department: undefined, job_title: undefined, level: undefined })
            }
          >
            Clear filters
          </Button>
        )}
      </Flex>

      <Content
        country={params.country}
        rows={rows}
        currency={currency}
        groupLabel={groupLabel}
        loading={isFetching}
        error={isError ? error : null}
      />
    </Flex>
  )
}

/** Everything under the controls: an invitation, a failure, or the figures. */
function Content({
  country,
  rows,
  currency,
  groupLabel,
  loading,
  error,
}: {
  country?: string
  rows: BreakdownRow[]
  currency: string | null
  groupLabel: string
  loading: boolean
  error: unknown
}) {
  if (!country) {
    return (
      <Empty
        description={
          <Typography.Text type="secondary">
            Choose a country to see how it pays. Pay is only ever compared within one
            country, because salaries are never converted between currencies.
          </Typography.Text>
        }
      />
    )
  }

  if (error) {
    return (
      <Alert
        type="error"
        showIcon
        message="Couldn't load this breakdown"
        description={errorMessage(error)}
      />
    )
  }

  return (
    <>
      {currency !== null && rows.length > 0 && (
        <MedianChart rows={rows} currency={currency} groupLabel={groupLabel} loading={loading} />
      )}

      <BreakdownTable
        rows={rows}
        loading={loading}
        groupLabel={groupLabel}
        currency={currency}
        emptyText={`Nobody in ${country} matches these filters.`}
      />
    </>
  )
}
