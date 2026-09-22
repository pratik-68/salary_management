// The list itself. Paging and sorting happen on the server: the browser is
// never sent 10,000 rows, so the table stays fast without any cached copy of
// the data to keep in step with edits.

import { Button, Table, Tooltip } from 'antd'
import type { TableProps } from 'antd'
import type { Employee, EmployeeListParams, PageMeta, SortDirection } from '../../api/types'
import { formatCount, formatDate, formatMoney } from '../../lib/format'
import { DEFAULT_DIRECTION, DEFAULT_SORT } from './useEmployeeListParams'

const PAGE_SIZE_OPTIONS = [25, 50, 100]

interface Props {
  employees: Employee[]
  meta?: PageMeta
  loading: boolean
  params: EmployeeListParams
  onChange: (patch: Partial<EmployeeListParams>) => void
  onEdit: (employee: Employee) => void
}

export default function EmployeeTable({
  employees,
  meta,
  loading,
  params,
  onChange,
  onEdit,
}: Props) {
  // Sorting by salary needs one currency to sort within, so the column only
  // becomes sortable once the list is filtered to a country. The API enforces
  // the same rule; this is what stops the user finding out by hitting an error.
  const salarySortable = Boolean(params.country)

  const columns: TableProps<Employee>['columns'] = [
    {
      title: 'Code',
      dataIndex: 'employee_code',
      key: 'employee_code',
      sorter: true,
      sortOrder: sortOrderFor('employee_code', params),
    },
    {
      title: 'Name',
      dataIndex: 'full_name',
      key: 'last_name',
      sorter: true,
      sortOrder: sortOrderFor('last_name', params),
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      sorter: true,
      sortOrder: sortOrderFor('email', params),
    },
    {
      title: 'Country',
      dataIndex: 'country_name',
      key: 'country_code',
      sorter: true,
      sortOrder: sortOrderFor('country_code', params),
      render: (name: string | null, employee) => name ?? employee.country_code,
    },
    {
      title: 'Department',
      dataIndex: 'department',
      key: 'department',
      sorter: true,
      sortOrder: sortOrderFor('department', params),
    },
    {
      title: 'Job title',
      dataIndex: 'job_title',
      key: 'job_title',
      sorter: true,
      sortOrder: sortOrderFor('job_title', params),
    },
    {
      title: 'Level',
      dataIndex: 'level',
      key: 'level',
      sorter: true,
      sortOrder: sortOrderFor('level', params),
    },
    {
      title: salarySortable ? (
        'Salary'
      ) : (
        <Tooltip title="Filter to one country to sort by salary. Salaries are never converted between currencies.">
          Salary
        </Tooltip>
      ),
      dataIndex: 'annual_salary',
      key: 'annual_salary',
      align: 'right',
      sorter: salarySortable,
      sortOrder: sortOrderFor('annual_salary', params),
      render: (salary: number, employee) => formatMoney(salary, employee.currency ?? ''),
    },
    {
      title: 'Hired',
      dataIndex: 'hire_date',
      key: 'hire_date',
      sorter: true,
      sortOrder: sortOrderFor('hire_date', params),
      render: (hireDate: string) => formatDate(hireDate),
    },
    {
      title: '',
      key: 'actions',
      fixed: 'right',
      width: 72,
      render: (_, employee) => (
        // The row already holds everything the form needs, so editing opens
        // straight away rather than fetching the same record again.
        <Button type="link" size="small" onClick={() => onEdit(employee)}>
          Edit
        </Button>
      ),
    },
  ]

  const handleChange: NonNullable<TableProps<Employee>['onChange']> = (pagination, _filters, sorter) => {
    const active = Array.isArray(sorter) ? sorter[0] : sorter
    const sort = active?.order ? String(active.columnKey) : DEFAULT_SORT
    const direction: SortDirection = active?.order === 'descend' ? 'desc' : DEFAULT_DIRECTION

    // A different order means a different first page, so paging starts again.
    const sortChanged = sort !== params.sort || direction !== params.direction

    onChange({
      sort,
      direction,
      page: sortChanged ? 1 : (pagination.current ?? 1),
      per_page: pagination.pageSize ?? params.per_page,
    })
  }

  return (
    <Table<Employee>
      rowKey="id"
      size="middle"
      dataSource={employees}
      columns={columns}
      loading={loading}
      onChange={handleChange}
      scroll={{ x: 'max-content' }}
      pagination={{
        current: params.page,
        pageSize: params.per_page,
        total: meta?.total ?? 0,
        showSizeChanger: true,
        pageSizeOptions: PAGE_SIZE_OPTIONS,
        showTotal: (total, range) =>
          `${formatCount(range[0])}–${formatCount(range[1])} of ${formatCount(total)}`,
      }}
    />
  )
}

function sortOrderFor(key: string, params: EmployeeListParams) {
  if (params.sort !== key) {
    return null
  }

  return params.direction === 'desc' ? ('descend' as const) : ('ascend' as const)
}
