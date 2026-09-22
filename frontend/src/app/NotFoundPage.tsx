import { Button, Result } from 'antd'
import { useNavigate } from 'react-router-dom'

export default function NotFoundPage() {
  const navigate = useNavigate()

  return (
    <Result
      status="404"
      title="Page not found"
      subTitle="That address doesn't match anything in the app."
      extra={
        <Button type="primary" onClick={() => navigate('/employees')}>
          Go to employees
        </Button>
      }
    />
  )
}
