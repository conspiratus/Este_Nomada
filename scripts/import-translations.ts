import fs from 'fs';
import path from 'path';
import { importTranslations } from '../lib/translations';
import { locales, type Locale } from '../lib/locales';

async function importAllTranslations() {
  console.log('🔄 Импортирую переводы из JSON файлов в БД...\n');

  for (const locale of locales) {
    try {
      const filePath = path.join(process.cwd(), 'messages', `${locale}.json`);
      const fileContent = fs.readFileSync(filePath, 'utf-8');
      const translations = JSON.parse(fileContent);

      console.log(`📝 Импортирую переводы для ${locale}...`);
      await importTranslations(locale, translations);
      console.log(`✅ Переводы для ${locale} импортированы\n`);
    } catch (error: any) {
      console.error(`❌ Ошибка при импорте переводов для ${locale}:`, error.message);
    }
  }

  console.log('✅ Импорт завершен!');
  process.exit(0);
}

importAllTranslations();

