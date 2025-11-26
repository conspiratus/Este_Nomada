import { notFound } from 'next/navigation';
import { getRequestConfig } from 'next-intl/server';
import { getTranslations } from './lib/translations-api';
import { locales, defaultLocale, type Locale } from './lib/locales';

async function loadMessages(locale: string): Promise<Record<string, any>> {
  try {
    // Пробуем загрузить из Django API (с таймаутом, чтобы не блокировать)
    try {
      const dbMessages = await Promise.race([
        getTranslations(locale as Locale),
        new Promise<Record<string, any>>((resolve) => 
          setTimeout(() => resolve({}), 3000) // 3 секунды таймаут
        )
      ]);
      
      if (dbMessages && Object.keys(dbMessages).length > 0) {
        console.log(`[i18n] Messages loaded from Django API for locale: ${locale}`);
        return dbMessages;
      }
    } catch (apiError) {
      console.warn(`[i18n] Failed to load from API for ${locale}, using files:`, apiError);
    }
    
    // Fallback на файлы, если в БД нет переводов или API недоступен
    console.log(`[i18n] Loading from files for locale: ${locale}`);
    const fileMessages = (await import(`./messages/${locale}.json`)).default;
    return fileMessages;
  } catch (error) {
    console.error(`[i18n] Error loading messages for locale ${locale}:`, error);
    // Fallback на файлы при ошибке
    try {
      const fileMessages = (await import(`./messages/${locale}.json`)).default;
      return fileMessages;
    } catch (fileError) {
      // Последний fallback на дефолтную локаль
      try {
        const defaultMessages = (await import(`./messages/${defaultLocale}.json`)).default;
        return defaultMessages;
      } catch (defaultError) {
        console.error(`[i18n] Error loading default messages:`, defaultError);
        return {};
      }
    }
  }
}

export default getRequestConfig(async ({ locale }) => {
  // Если locale undefined (например, в API routes или при статической генерации),
  // используем defaultLocale без логирования ошибки
  if (!locale || typeof locale !== 'string') {
    // Только логируем, если это не API route (API routes не должны использовать i18n)
    const isApiRoute = typeof window === 'undefined' && 
                      process.env.NEXT_RUNTIME === 'nodejs' &&
                      !process.env.NEXT_PHASE;
    
    if (!isApiRoute) {
      console.log('[i18n] getRequestConfig called with undefined locale, using default:', defaultLocale);
    }
    
    const validLocale = defaultLocale;
    const messages = await loadMessages(validLocale);
    return {
      locale: validLocale,
      messages
    };
  }
  
  console.log('[i18n] getRequestConfig called with locale:', locale, 'type:', typeof locale);
  
  // Проверяем, что locale находится в списке допустимых локалей
  if (!locales.includes(locale as Locale)) {
    console.warn('[i18n] Invalid locale:', locale, 'type:', typeof locale, 'allowed:', locales, '- using default');
    const validLocale = defaultLocale;
    const messages = await loadMessages(validLocale);
    return {
      locale: validLocale,
      messages
    };
  }

  const validLocale = locale as string;
  const messages = await loadMessages(validLocale);
  console.log('[i18n] Messages loaded successfully for locale:', validLocale);
  
  return {
    locale: validLocale,
    messages
  };
});
