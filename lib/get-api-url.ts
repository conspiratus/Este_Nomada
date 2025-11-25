/**
 * Получает URL API на основе текущего домена или переменной окружения.
 * Использует относительный путь для работы на любом домене.
 */
export function getApiUrl(): string {
  // В браузере используем относительный путь
  if (typeof window !== 'undefined') {
    return '/api';
  }
  
  // На сервере (SSR) используем переменную окружения или дефолт
  return process.env.NEXT_PUBLIC_API_URL || 'https://estenomada.es/api';
}


