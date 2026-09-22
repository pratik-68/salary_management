// Sign-in. Everything in the app is behind it, because salary data is
// sensitive and there is nothing here that is safe to show a stranger.

import { Alert, Button, Card, Flex, Form, Input, Spin, Typography, theme } from 'antd'
import { Navigate, useLocation } from 'react-router-dom'
import { errorMessage } from '../../api/client'
import { useSession, useSignIn } from '../../api/session'
import type { Credentials } from '../../api/session'

export default function LoginPage() {
  const { data: user, isPending } = useSession()
  const signIn = useSignIn()
  const location = useLocation()
  const { token } = theme.useToken()

  // Where the guard turned them away from, so signing in carries on to the
  // page they asked for — filters and all — rather than always landing here.
  const from = (location.state as { from?: string } | null)?.from ?? '/employees'

  if (isPending) {
    return <Spin fullscreen />
  }

  // Also covers a successful sign-in: the mutation writes the user into the
  // cache, this re-renders, and the redirect does the navigating.
  if (user) {
    return <Navigate to={from} replace />
  }

  return (
    <Flex
      align="center"
      justify="center"
      style={{ minHeight: '100vh', padding: 24, background: token.colorBgLayout }}
    >
      <Card style={{ width: '100%', maxWidth: 380 }}>
        <Typography.Title level={4} style={{ marginTop: 0 }}>
          Salary Management
        </Typography.Title>
        <Typography.Paragraph type="secondary">
          Sign in to manage employee and pay data.
        </Typography.Paragraph>

        {signIn.isError && (
          <Alert
            type="error"
            showIcon
            style={{ marginBottom: 16 }}
            message={errorMessage(signIn.error)}
          />
        )}

        <Form<Credentials>
          layout="vertical"
          requiredMark={false}
          onFinish={(credentials) => signIn.mutate(credentials)}
        >
          <Form.Item
            label="Email"
            name="email_address"
            rules={[{ required: true, message: 'Enter your email address.' }]}
          >
            <Input type="email" autoComplete="username" autoFocus size="large" />
          </Form.Item>

          <Form.Item
            label="Password"
            name="password"
            rules={[{ required: true, message: 'Enter your password.' }]}
          >
            <Input.Password autoComplete="current-password" size="large" />
          </Form.Item>

          {/* An antd button ignores clicks while loading, so this is also what
              stops a double submit. */}
          <Button type="primary" htmlType="submit" size="large" block loading={signIn.isPending}>
            Sign in
          </Button>
        </Form>
      </Card>
    </Flex>
  )
}
