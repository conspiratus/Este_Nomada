import mysql from 'mysql2/promise';

// Конфигурация подключения к БД
// Для one.com обычно используется localhost или специальный хост
const dbConfig = {
  host: process.env.DB_HOST || 'mysql.czjey8yl0.service.one',
  user: process.env.DB_USER || 'czjey8yl0_estenomada',
  password: process.env.DB_PASSWORD || 'Jovi4AndMay2020!',
  database: process.env.DB_NAME || 'czjey8yl0_estenomada',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT) : 3306,
};

// Создаём пул соединений
let pool: mysql.Pool | null = null;
let poolError: Error | null = null;

// Проверяем, идет ли сборка проекта
function isBuildTime(): boolean {
  // Проверяем различные признаки сборки
  if (process.env.NEXT_PHASE === 'phase-production-build') {
    return true;
  }
  
  // Если это production и нет runtime, вероятно идет сборка
  if (process.env.NODE_ENV === 'production' && 
      !process.env.VERCEL && 
      typeof process.env.NEXT_RUNTIME === 'undefined') {
    // Но нужно быть осторожным - это может быть и runtime
    // Поэтому проверяем наличие процесса сборки через другие признаки
    return false; // Будем проверять по ошибкам подключения
  }
  
  return false;
}

export function getPool(): mysql.Pool {
  if (!pool) {
    try {
      pool = mysql.createPool(dbConfig);
      poolError = null;
    } catch (error: any) {
      poolError = error;
      console.error('[DB] Error creating pool:', error?.message || String(error));
      throw error;
    }
  }
  return pool;
}

// Функция для выполнения запросов
export async function query<T = any>(
  sql: string,
  params?: any[]
): Promise<T> {
  try {
    const connection = getPool();
    const [results] = await connection.execute(sql, params || []);
    return results as T;
  } catch (error: any) {
    const errorMessage = error?.message || String(error);
    const errorCode = error?.code || '';
    
    // Логируем ошибку, но не прерываем выполнение
    console.error('Database query error:', errorMessage);
    
    // Если это ошибка подключения (ENOTFOUND, ECONNREFUSED и т.д.), 
    // это нормально при сборке - просто возвращаем пустой результат
    if (errorCode === 'ENOTFOUND' || 
        errorCode === 'ECONNREFUSED' || 
        errorMessage.includes('getaddrinfo') ||
        errorMessage.includes('connect')) {
      console.warn('[DB] Connection error (likely during build): returning empty result');
      return [] as T;
    }
    
    // В dev режиме выбрасываем ошибку для отладки (только если это не ошибка подключения)
    if (process.env.NODE_ENV === 'development') {
      // Но не выбрасываем ошибки подключения, так как БД может быть недоступна
      if (!errorMessage.includes('getaddrinfo') && 
          !errorMessage.includes('connect') &&
          errorCode !== 'ENOTFOUND' && 
          errorCode !== 'ECONNREFUSED') {
        throw error;
      }
    }
    
    // В production и при сборке всегда возвращаем пустой результат
    return [] as T;
  }
}

// Закрытие пула (для graceful shutdown)
export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

