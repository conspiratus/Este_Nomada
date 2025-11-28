/**
 * Утилиты для работы с JWT аутентификацией
 */

const ACCESS_TOKEN_KEY = 'access_token';
const REFRESH_TOKEN_KEY = 'refresh_token';

/**
 * Сохраняет JWT токены в localStorage
 */
export function saveTokens(access: string, refresh: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(ACCESS_TOKEN_KEY, access);
  localStorage.setItem(REFRESH_TOKEN_KEY, refresh);
}

/**
 * Получает access токен из localStorage
 */
export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

/**
 * Получает refresh токен из localStorage
 */
export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

/**
 * Удаляет токены из localStorage
 */
export function clearTokens(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

/**
 * Проверяет, есть ли сохраненный токен
 */
export function hasToken(): boolean {
  return getAccessToken() !== null;
}

/**
 * Обновляет access токен используя refresh токен
 */
export async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return null;

  try {
    const apiUrl = typeof window !== 'undefined' 
      ? window.location.origin + '/api'
      : process.env.NEXT_PUBLIC_API_URL || 'https://estenomada.es/api';
    
    const response = await fetch(`${apiUrl}/token/refresh/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh: refreshToken }),
    });

    if (response.ok) {
      const data = await response.json();
      if (data.access) {
        saveTokens(data.access, refreshToken);
        return data.access;
      }
    }
  } catch (error) {
    console.error('Error refreshing token:', error);
  }

  // Если обновление не удалось, очищаем токены
  clearTokens();
  return null;
}

/**
 * Выполняет запрос с JWT токеном в заголовках
 */
export async function fetchWithAuth(
  url: string,
  options: RequestInit = {}
): Promise<Response> {
  const token = getAccessToken();
  
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  if (token) {
    (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
  }

  let response = await fetch(url, {
    ...options,
    headers,
    credentials: 'include',
  });

  // Если получили 401, пытаемся обновить токен
  if (response.status === 401 && token) {
    const newToken = await refreshAccessToken();
    if (newToken) {
      // Повторяем запрос с новым токеном
      (headers as Record<string, string>)['Authorization'] = `Bearer ${newToken}`;
      response = await fetch(url, {
        ...options,
        headers,
        credentials: 'include',
      });
    }
  }

  return response;
}

