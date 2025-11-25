import { query } from './db';
import { locales, type Locale } from '@/lib/locales';

export interface Translation {
  id: number;
  locale: string;
  namespace: string;
  key: string;
  value: string;
}

/**
 * Загружает все переводы для указанной локали
 */
export async function getTranslations(locale: Locale): Promise<Record<string, any>> {
  try {
    const translations = await query<Translation[]>(
      'SELECT namespace, `key`, value FROM translations WHERE locale = ?',
      [locale]
    );

    // Преобразуем плоский список в вложенную структуру
    const result: Record<string, any> = {};
    
    for (const trans of translations) {
      if (!result[trans.namespace]) {
        result[trans.namespace] = {};
      }
      result[trans.namespace][trans.key] = trans.value;
    }

    return result;
  } catch (error) {
    console.error('[Translations] Error loading translations:', error);
    return {};
  }
}

/**
 * Сохраняет или обновляет перевод
 */
export async function setTranslation(
  locale: Locale,
  namespace: string,
  key: string,
  value: string
): Promise<void> {
  await query(
    `INSERT INTO translations (locale, namespace, \`key\`, value) 
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE value = VALUES(value), updated_at = CURRENT_TIMESTAMP`,
    [locale, namespace, key, value]
  );
}

/**
 * Удаляет перевод
 */
export async function deleteTranslation(
  locale: Locale,
  namespace: string,
  key: string
): Promise<void> {
  await query(
    'DELETE FROM translations WHERE locale = ? AND namespace = ? AND `key` = ?',
    [locale, namespace, key]
  );
}

/**
 * Импортирует переводы из JSON объекта
 */
export async function importTranslations(
  locale: Locale,
  translations: Record<string, any>
): Promise<void> {
  for (const [namespace, keys] of Object.entries(translations)) {
    if (typeof keys === 'object' && keys !== null) {
      for (const [key, value] of Object.entries(keys)) {
        if (typeof value === 'string') {
          await setTranslation(locale, namespace, key, value);
        }
      }
    }
  }
}

