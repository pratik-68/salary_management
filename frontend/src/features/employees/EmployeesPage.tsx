import { Alert, Typography } from 'antd'
import { errorMessage } from '../../api/client'
import { useEmployees } from '../../api/employees'
import EmployeeFilterBar from './EmployeeFilterBar'
import EmployeeTable from './EmployeeTable'
import { useEmployeeListParams } from './useEmployeeListParams'

export default function EmployeesPage() {
  const { params, update } = useEmployeeListParams()
  const { data, isFetching, isError, error } = useEmployees(params)

  return (
    <>
      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Employees
      </Typography.Title>

      <EmployeeFilterBar params={params} onChange={update} />

      {isError ? (
        // Mostly a filter the API does not recognise, typed into the URL by
        // hand. Its own message says which one, so it is passed through.
        <Alert
          type="error"
          showIcon
          message="Couldn't load the employee list"
          description={errorMessage(error)}
        />
      ) : (
        <EmployeeTable
          employees={data?.data ?? []}
          meta={data?.meta}
          loading={isFetching}
          params={params}
          onChange={update}
        />
      )}
    </>
  )
}
