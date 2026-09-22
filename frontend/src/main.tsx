import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
// Ant Design's own reset, in place of a separate normalize step.
import 'antd/dist/reset.css'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
