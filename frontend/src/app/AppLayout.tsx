// The frame every signed-in page sits in: the two areas of the app on the
// left, who is signed in on the right, and the page itself in the middle.

import { Button, Layout, Menu, Space, Typography, theme } from 'antd'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useSession, useSignOut } from '../api/session'

// The keys are the paths, so choosing an item and highlighting the current one
// are the same piece of information rather than two lists kept in step.
const NAV_ITEMS = [
  { key: '/employees', label: 'Employees' },
  { key: '/insights', label: 'Insights' },
]

export default function AppLayout() {
  const navigate = useNavigate()
  const { pathname } = useLocation()
  const { data: user } = useSession()
  const signOut = useSignOut()
  const { token } = theme.useToken()

  // Matched by prefix so a page below a section — one employee, say — keeps
  // its section highlighted.
  const selectedKeys = NAV_ITEMS.map((item) => item.key).filter((key) => pathname.startsWith(key))

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Layout.Sider breakpoint="lg" collapsedWidth={0} width={220}>
        <Typography.Title
          level={5}
          style={{ color: token.colorTextLightSolid, margin: 0, padding: '16px 24px' }}
        >
          Salary Management
        </Typography.Title>
        <Menu
          theme="dark"
          mode="inline"
          items={NAV_ITEMS}
          selectedKeys={selectedKeys}
          onClick={({ key }) => navigate(key)}
        />
      </Layout.Sider>

      <Layout>
        <Layout.Header
          style={{
            background: token.colorBgContainer,
            borderBottom: `1px solid ${token.colorSplit}`,
            display: 'flex',
            justifyContent: 'flex-end',
            alignItems: 'center',
          }}
        >
          <Space>
            <Typography.Text type="secondary">{user?.email_address}</Typography.Text>
            {/* No confirmation: signing out is one click to undo. */}
            <Button onClick={() => signOut.mutate()} loading={signOut.isPending}>
              Sign out
            </Button>
          </Space>
        </Layout.Header>

        <Layout.Content style={{ padding: 24 }}>
          <Outlet />
        </Layout.Content>
      </Layout>
    </Layout>
  )
}
