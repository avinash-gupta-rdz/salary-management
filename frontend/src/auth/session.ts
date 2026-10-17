// Basic auth credentials for the single HR login. Kept in sessionStorage so a
// page refresh keeps you signed in, but closing the tab signs you out.
const KEY = 'salary-management.auth'

export function encodeCredentials(username: string, password: string): string {
  return btoa(`${username}:${password}`)
}

export function getToken(): string | null {
  try {
    return sessionStorage.getItem(KEY)
  } catch {
    return null
  }
}

export function saveToken(token: string): void {
  try {
    sessionStorage.setItem(KEY, token)
  } catch {
    // Storage unavailable (e.g. private mode): stay signed in for this page only.
  }
}

export function clearToken(): void {
  try {
    sessionStorage.removeItem(KEY)
  } catch {
    // Nothing stored.
  }
}
