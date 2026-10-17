import AppBar from '@mui/material/AppBar'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import Container from '@mui/material/Container'
import Toolbar from '@mui/material/Toolbar'
import Typography from '@mui/material/Typography'
import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'

const navItems = [
  { to: '/employees', label: 'Employees' },
  { to: '/insights', label: 'Insights' },
]

export default function Layout() {
  const { logout } = useAuth()

  return (
    <>
      <AppBar position="static" elevation={0}>
        <Toolbar sx={{ gap: 1, flexWrap: 'wrap' }}>
          <Typography variant="h6" component="div" sx={{ mr: 3 }}>
            Salary Management
          </Typography>
          <Box component="nav" sx={{ display: 'flex', gap: 1, flexGrow: 1 }}>
            {navItems.map((item) => (
              <Button
                key={item.to}
                component={NavLink}
                to={item.to}
                color="inherit"
                sx={{ opacity: 0.8, '&.active': { opacity: 1, bgcolor: 'rgba(255,255,255,0.15)' } }}
              >
                {item.label}
              </Button>
            ))}
          </Box>
          <Button color="inherit" onClick={logout}>
            Sign out
          </Button>
        </Toolbar>
      </AppBar>
      <Container maxWidth="xl" sx={{ py: 3 }}>
        <Outlet />
      </Container>
    </>
  )
}
