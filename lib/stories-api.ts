/**
 * Функции для работы с историями через Django API.
 */
import { type Locale } from '@/lib/locales';
import { Post } from '@/types/post';

/**
 * Получает API URL для Server Components на основе текущего домена.
 * Используется только на сервере.
 */
async function getServerApiUrl(): Promise<string> {
  if (typeof window !== 'undefined') {
    // На клиенте не должно вызываться
    return '/api';
  }
  
  try {
    // Динамический импорт headers только на сервере
    const { headers } = await import('next/headers');
    const headersList = await headers();
    const host = headersList.get('host') || 'estenomada.es';
    const protocol = headersList.get('x-forwarded-proto') || 'https';
    return `${protocol}://${host}/api`;
  } catch {
    // Fallback для случаев, когда headers недоступны
    return process.env.NEXT_PUBLIC_API_URL || 'https://estenomada.es/api';
  }
}

export interface Story {
  id: number;
  date: string;
  cover_image: string | null;
  coverImage?: string;
  source: 'manual' | 'telegram';
  published: boolean;
  title: string;
  slug: string;
  excerpt: string | null;
  content: string;
}

/**
 * Получает истории из Django API.
 */
export async function getStories(
  locale?: Locale,
  limit?: number,
  offset?: number
): Promise<Story[]> {
  try {
    const apiUrl = await getServerApiUrl();
    // Используем URL только для серверных запросов (когда apiUrl полный)
    let url: string;
    if (apiUrl.startsWith('http')) {
      const urlObj = new URL(`${apiUrl}/stories/public/`);
      if (locale) {
        urlObj.searchParams.append('locale', locale);
      }
      if (limit) {
        urlObj.searchParams.append('limit', limit.toString());
      }
      if (offset) {
        urlObj.searchParams.append('offset', offset.toString());
      }
      url = urlObj.toString();
    } else {
      // Для клиентских запросов используем относительный путь
      const params = new URLSearchParams();
      if (locale) params.append('locale', locale);
      if (limit) params.append('limit', limit.toString());
      if (offset) params.append('offset', offset.toString());
      const queryString = params.toString();
      url = `${apiUrl}/stories/public/${queryString ? `?${queryString}` : ''}`;
    }

    const response = await fetch(url, {
      next: { revalidate: 300 }, // Кешируем на 5 минут
    });

    if (!response.ok) {
      console.error('[Stories API] Error:', response.status, url);
      return [];
    }

    const data = await response.json();
    
    // Обрабатываем ответ API
    const stories = Array.isArray(data) ? data : (data.results || []);
    
    if (stories.length === 0) {
      console.warn('[Stories API] No stories found for locale:', locale);
      return [];
    }
    
    const processedStories = stories
      .filter((story: any) => story && story.published !== false) // Фильтруем только опубликованные
      .map((story: any) => {
        // API уже возвращает данные для нужной локали в корне объекта
        // Но также может быть массив translations - игнорируем его, используем корневые поля
        // Приоритет: coverImage (из get_coverImage) > cover_image_file > cover_image
        const coverImage = story.coverImage || story.cover_image_file || story.cover_image || null;
        return {
          id: story.id,
          date: story.date,
          cover_image: coverImage,
          coverImage: coverImage,
          source: story.source || 'manual',
          published: story.published !== false,
          title: story.title || '',
          slug: story.slug || '',
          excerpt: story.excerpt || null,
          content: story.content || '',
        };
      });
    
    console.log(`[Stories API] Loaded ${processedStories.length} stories for locale: ${locale}`);
    return processedStories;
  } catch (error) {
    console.error('[Stories API] Error fetching stories:', error);
    return [];
  }
}

/**
 * Получает историю по slug из Django API.
 */
export async function getStoryBySlug(locale: Locale, slug: string): Promise<Story | null> {
  try {
    const apiUrl = await getServerApiUrl();
    // Используем URL только для серверных запросов (когда apiUrl полный)
    let url: string;
    if (apiUrl.startsWith('http')) {
      const urlObj = new URL(`${apiUrl}/stories/${slug}/`);
      urlObj.searchParams.append('locale', locale);
      url = urlObj.toString();
    } else {
      // Для клиентских запросов используем относительный путь
      url = `${apiUrl}/stories/${slug}/?locale=${locale}`;
    }
    
    const response = await fetch(url, {
      next: { revalidate: 300 }, // Кешируем на 5 минут
    });

    if (!response.ok) {
      return null;
    }

    const story = await response.json();
    
    // Приоритет: coverImage (из get_coverImage) > cover_image_file > cover_image
    const coverImage = story.coverImage || story.cover_image_file || story.cover_image || null;
    
    return {
      id: story.id,
      date: story.date,
      cover_image: coverImage,
      coverImage: coverImage,
      source: story.source,
      published: story.published,
      title: story.title || '',
      slug: story.slug || '',
      excerpt: story.excerpt,
      content: story.content || '',
    };
  } catch (error) {
    console.error('[Stories API] Error fetching story by slug:', error);
    return null;
  }
}

