import { Alert, Typography } from 'antd'

// A placeholder, as with the employee list.
export default function InsightsPage() {
  return (
    <>
      <Typography.Title level={3}>Insights</Typography.Title>
      <Alert
        type="info"
        showIcon
        message="Pay insights are next"
        description="Pay by country, and pay within one country by department, job title or level — every figure in its own currency, none of them converted."
      />
    </>
  )
}
