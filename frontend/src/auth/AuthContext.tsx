import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { ApiError, apiRequest, setUnauthorizedHandler } from '../api/client'
import { clearToken, encodeCredentials, getToken, saveToken } from './session'
import { AuthContext } from './useAuth'

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [token, setToken] = useState<string | null>(getToken)

  const logout = useCallback(() => {
    clearToken()
    setToken(null)
    queryClient.clear()
  }, [queryClient])

  useEffect(() => setUnauthorizedHandler(logout), [logout])

  const login = useCallback(async (username: string, password: string) => {
    const candidate = encodeCredentials(username, password)
    try {
      await apiRequest('/meta', { token: candidate })
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) throw new Error('Wrong username or password')
      throw error
    }
    saveToken(candidate)
    setToken(candidate)
  }, [])

  const value = useMemo(() => ({ isAuthenticated: token !== null, login, logout }), [token, login, logout])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}
