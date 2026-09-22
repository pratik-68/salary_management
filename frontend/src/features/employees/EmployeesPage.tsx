import { Alert, Button, Flex, Typography } from 'antd'
import { useState } from 'react'
import { errorMessage } from '../../api/client'
import { useEmployees } from '../../api/employees'
import type { Employee } from '../../api/types'
import EmployeeFilterBar from './EmployeeFilterBar'
import EmployeeFormDrawer from './EmployeeFormDrawer'
import EmployeeTable from './EmployeeTable'
import { useEmployeeListParams } from './useEmployeeListParams'

export default function EmployeesPage() {
  const { params, update } = useEmployeeListParams()
  const { data, isFetching, isError, error } = useEmployees(params)

  // Which employee the drawer is for, kept apart from whether it is open so
  // the name in its title does not vanish as it slides shut.
  const [editing, setEditing] = useState<Employee | undefined>(undefined)
  const [drawerOpen, setDrawerOpen] = useState(false)

  const openDrawer = (employee?: Employee) => {
    setEditing(employee)
    setDrawerOpen(true)
  }

  return (
    <>
      <Flex justify="space-between" align="center">
        <Typography.Title level={3} style={{ marginTop: 0 }}>
          Employees
        </Typography.Title>
        <Button type="primary" onClick={() => openDrawer()}>
          Add employee
        </Button>
      </Flex>

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
          onEdit={openDrawer}
        />
      )}

      <EmployeeFormDrawer
        open={drawerOpen}
        employee={editing}
        onClose={() => setDrawerOpen(false)}
      />
    </>
  )
}
