// The guard every page sits behind. The API refuses unauthenticated requests
// on its own; this is what makes that refusal look like a login page instead
// of a broken screen.

import { Spin } from 'antd'
import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useSession } from '../api/session'

export default function RequireAuth() {
  const { data: user, isPending } = useSession()
  const location = useLocation()

  // Still asking the server who this is. Showing the login page here would
  // flash it at someone who turns out to be signed in already.
  if (isPending) {
    return <Spin fullscreen />
  }

  if (!user) {
    return (
      <Navigate to="/login" replace state={{ from: `${location.pathname}${location.search}` }} />
    )
  }

  return <Outlet />
}
