/**
 * Функции для работы с меню через Django API.
 */
import { type Locale } from '@/lib/locales';

export interface MenuItemImage {
  id: number;
  image_url: string;
  order: number;
}

export interface MenuItemAttribute {
  id: number;
  locale: string;
  name: string;
  value: string;
  order: number;
}

export interface RelatedStory {
  id: number;
  title: string;
  slug: string;
  excerpt: string | null;
  coverImage: string | null;
  date: string;
}

export interface MenuItemCategory {
  id: number | null;
  order_id: number;
  name: string;
  description: string | null;
}

export interface MenuItem {
  id: number;
  price: number | null;
  image: string | null;
  images?: MenuItemImage[];
  attributes?: MenuItemAttribute[];
  related_stories?: RelatedStory[];
  order: number;
  active: boolean;
  name: string;
  description: string | null;
  category: MenuItemCategory | null;
  stock_quantity?: number | null;
  low_stock?: boolean;
}

export interface MenuCategoryGroup {
  id: number | null;
  order_id: number;
  name: string;
  description: string | null;
  items: MenuItem[];
}

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

/**
 * Получает элементы меню из Django API.
 * Работает как на сервере (Server Components), так и на клиенте.
 */
export async function getMenuItems(locale?: Locale): Promise<MenuItem[]> {
  try {
    // Определяем, на сервере мы или на клиенте
    let apiUrl: string;
    if (typeof window === 'undefined') {
      // Серверный запрос - используем динамический URL
      apiUrl = await getServerApiUrl();
    } else {
      // Клиентский запрос - используем относительный путь
      apiUrl = '/api';
    }
    
    // Строим URL
    let url: string;
    if (apiUrl.startsWith('http')) {
      // Серверный запрос - используем полный URL
      const urlObj = new URL(`${apiUrl}/menu/`);
      if (locale) {
        urlObj.searchParams.append('locale', locale);
      }
      url = urlObj.toString();
    } else {
      // Клиентский запрос - используем относительный путь
      url = `${apiUrl}/menu/`;
      if (locale) {
        const separator = url.includes('?') ? '&' : '?';
        url = `${url}${separator}locale=${locale}`;
      }
    }
    
    // Для серверных компонентов используем кеширование с revalidate
    // Это позволяет статической генерации работать корректно
    // Страница с revalidate=60 будет регенерироваться каждую минуту
    const fetchOptions: RequestInit = typeof window === 'undefined' 
      ? {
          // На сервере используем кеширование для статической генерации
          cache: 'force-cache',
          next: { revalidate: 60 } // Регенерируем каждую минуту
        }
      : {
          // На клиенте не кешируем для получения актуальных данных
          cache: 'no-store'
        };
    
    const response = await fetch(url, fetchOptions);

    if (!response.ok) {
      console.error('[Menu API] Error:', response.status);
      return [];
    }

    const data = await response.json();
    
    // Если это пагинация DRF
    if (data.results) {
      const items = data.results.map((item: any) => ({
        id: item.id,
        price: item.price ? parseFloat(item.price) : null,
        image: item.image,
        images: item.images || [],
        attributes: item.attributes || [],
        related_stories: item.related_stories || [],
        order: item.order || 0,
        active: item.active !== false,
        name: item.name || '',
        // Используем description из корня (уже обработан сериализатором с учетом локали)
        description: item.description || null,
        category: item.category || '',
      }));
      console.log(`[Menu API] Loaded ${items.length} items for locale: ${locale}`);
      if (items.length > 0) {
        console.log(`[Menu API] First item description (${items[0].name}):`, items[0].description ? `${items[0].description.substring(0, 100)}...` : 'None');
      }
      return items;
    }
    
    // Если это просто массив
    const items = data.map((item: any) => ({
      id: item.id,
      price: item.price ? parseFloat(item.price) : null,
      image: item.image,
      images: item.images || [],
      attributes: item.attributes || [],
      related_stories: item.related_stories || [],
      order: item.order || 0,
      active: item.active !== false,
      name: item.name || '',
      // Используем description из корня (уже обработан сериализатором с учетом локали)
      description: item.description || null,
      category: item.category || '',
    }));
    console.log(`[Menu API] Loaded ${items.length} items for locale: ${locale}`);
    if (items.length > 0) {
      console.log(`[Menu API] First item description (${items[0].name}):`, items[0].description ? `${items[0].description.substring(0, 100)}...` : 'None');
    }
    return items;
  } catch (error) {
    console.error('[Menu API] Error fetching menu items:', error);
    return [];
  }
}

