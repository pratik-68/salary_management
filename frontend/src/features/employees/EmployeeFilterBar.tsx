// Everything that narrows the list: one search box and the four filters the
// API understands. Each one writes straight to the URL.

import { Button, Flex, Input, Select } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useReferenceData } from '../../api/meta'
import type { EmployeeListParams } from '../../api/types'

const SEARCH_DEBOUNCE_MS = 300

interface Props {
  params: EmployeeListParams
  onChange: (patch: Partial<EmployeeListParams>) => void
}

export default function EmployeeFilterBar({ params, onChange }: Props) {
  const { data: catalog } = useReferenceData()

  // Stable, so that a re-render in the middle of typing does not restart the
  // search box's debounce.
  const handleSearch = useCallback((q?: string) => onChange({ q }), [onChange])

  // Once a department is chosen, only its own titles are offered — an
  // Accountant in Engineering is a mistake the API would reject anyway. With
  // no department, every title is offered, so a title can be picked first.
  const jobTitles = params.department
    ? (catalog?.departments.find((department) => department.name === params.department)?.job_titles ?? [])
    : (catalog?.job_titles ?? [])

  const hasFilters = Boolean(
    params.q || params.country || params.department || params.job_title || params.level,
  )

  return (
    <Flex wrap gap="small" align="center" style={{ marginBottom: 16 }}>
      <SearchBox value={params.q} onChange={handleSearch} />

      <Select
        allowClear
        showSearch
        optionFilterProp="label"
        placeholder="Country"
        style={{ minWidth: 190 }}
        value={params.country}
        onChange={(country?: string) => onChange({ country })}
        options={(catalog?.countries ?? []).map((country) => ({
          value: country.code,
          // The currency is part of what makes a country the unit of
          // comparison here, so it is on the label rather than hidden.
          label: `${country.name} (${country.currency})`,
        }))}
      />

      <Select
        allowClear
        showSearch
        optionFilterProp="label"
        placeholder="Department"
        style={{ minWidth: 180 }}
        value={params.department}
        // A title from the old department would show nobody, so it goes when
        // the department changes.
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
            onChange({
              q: undefined,
              country: undefined,
              department: undefined,
              job_title: undefined,
              level: undefined,
            })
          }
        >
          Clear filters
        </Button>
      )}
    </Flex>
  )
}

/**
 * Typing is local; the URL only catches up once the user pauses. Writing every
 * keystroke to the URL would put a history entry and a request behind each
 * letter.
 */
function SearchBox({ value, onChange }: { value?: string; onChange: (value?: string) => void }) {
  const [text, setText] = useState(value ?? '')
  const [lastFromUrl, setLastFromUrl] = useState(value)

  // The URL can also change from elsewhere — the back button, or Clear
  // filters — and the box has to follow it. Adjusted during render rather
  // than in an effect, so there is no flash of the stale text.
  if (value !== lastFromUrl) {
    setLastFromUrl(value)
    setText(value ?? '')
  }

  useEffect(() => {
    if (text === (value ?? '')) {
      return
    }

    const timer = setTimeout(() => onChange(text || undefined), SEARCH_DEBOUNCE_MS)
    return () => clearTimeout(timer)
  }, [text, value, onChange])

  return (
    <Input
      allowClear
      value={text}
      onChange={(event) => setText(event.target.value)}
      placeholder="Search name, email or code"
      style={{ width: 260 }}
    />
  )
}
