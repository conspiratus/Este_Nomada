/**
 * Утилита для кеширования API запросов на клиенте
 * Улучшает производительность за счет избежания дублирующих запросов
 */

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number; // Time to live в миллисекундах
}

class ApiCache {
  private cache = new Map<string, CacheEntry<any>>();

  /**
   * Получает данные из кеша или выполняет запрос
   */
  async fetch<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl: number = 60000 // 1 минута по умолчанию
  ): Promise<T> {
    const cached = this.cache.get(key);
    
    if (cached && Date.now() - cached.timestamp < cached.ttl) {
      return cached.data;
    }

    const data = await fetcher();
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl,
    });

    return data;
  }

  /**
   * Очищает кеш
   */
  clear(key?: string) {
    if (key) {
      this.cache.delete(key);
    } else {
      this.cache.clear();
    }
  }
}

export const apiCache = new ApiCache();

