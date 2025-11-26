/**
 * Функции для работы с переводами через Django API.
 */
import { type Locale } from '@/lib/locales';
import { headers } from 'next/headers';

/**
 * Получает API URL для Server Components на основе текущего домена.
 */
async function getServerApiUrl(): Promise<string> {
  try {
    const headersList = headers();
    const host = headersList.get('host') || 'estenomada.es';
    const protocol = headersList.get('x-forwarded-proto') || 'https';
    return `${protocol}://${host}/api`;
  } catch {
    // Fallback для случаев, когда headers недоступны
    return process.env.NEXT_PUBLIC_API_URL || 'https://estenomada.es/api';
  }
}

/**
 * Загружает все переводы для указанной локали из Django API.
 * Используется в Server Components, поэтому нужен полный URL.
 */
export async function getTranslations(locale: Locale): Promise<Record<string, any>> {
  try {
    // В Server Components нужно использовать полный URL на основе текущего домена
    const apiUrl = await getServerApiUrl();
    
    const url = `${apiUrl}/translations/by_locale/?locale=${locale}`;
    
    // В Server Components используем fetch с таймаутом
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000); // 5 секунд таймаут
    
    try {
      const response = await fetch(url, {
        next: { revalidate: 3600 }, // Кешируем переводы на 1 час (они редко меняются)
        signal: controller.signal,
        headers: {
          'Accept': 'application/json',
        },
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        console.warn(`[Translations API] Error loading translations for ${locale}:`, response.status);
        return {};
      }

      const translations = await response.json();
      return translations || {};
    } catch (fetchError: any) {
      clearTimeout(timeoutId);
      if (fetchError.name === 'AbortError') {
        console.warn(`[Translations API] Timeout loading translations for ${locale}`);
      } else {
        throw fetchError;
      }
      return {};
    }
  } catch (error) {
    console.error(`[Translations API] Error fetching translations for ${locale}:`, error);
    // Возвращаем пустой объект, чтобы fallback на файлы сработал
    return {};
  }
}

