import { Alert, Typography } from 'antd'

// A placeholder until the list lands: the shell and the guard are what this
// slice is about, and an empty route would make neither visible.
export default function EmployeesPage() {
  return (
    <>
      <Typography.Title level={3}>Employees</Typography.Title>
      <Alert
        type="info"
        showIcon
        message="The employee list is next"
        description="Search, filters, sorting and the create and edit form arrive in the next slice. The API behind them is already in place."
      />
    </>
  )
}
