import fs from 'fs';
import path from 'path';
import { query } from '../lib/db';

async function initDatabase() {
  try {
    console.log('Initializing database...');
    
    // Читаем SQL файл
    const sqlPath = path.join(process.cwd(), 'lib', 'db-init.sql');
    const sql = fs.readFileSync(sqlPath, 'utf-8');
    
    // Разбиваем на отдельные запросы
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));
    
    // Выполняем каждый запрос
    for (const statement of statements) {
      if (statement) {
        try {
          await query(statement);
          console.log('✓ Executed:', statement.substring(0, 50) + '...');
        } catch (error: any) {
          // Игнорируем ошибки "таблица уже существует"
          if (!error.message.includes('already exists')) {
            console.error('Error executing statement:', error.message);
          }
        }
      }
    }
    
    console.log('Database initialized successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

initDatabase();



