/**
 * Функции для работы с Hero секцией через Django API.
 */
import { getApiUrl } from './get-api-url';

const API_URL = getApiUrl();

export interface HeroImage {
  id: number;
  image_url: string;
  order: number;
  active: boolean;
}

export type TransitionEffect = 'crossfade' | 'fade' | 'slide';

export type ButtonStyle = 'primary' | 'secondary' | 'outline' | 'ghost';

export interface HeroButton {
  id: number;
  order: number;
  url: string;
  style: ButtonStyle;
  active: boolean;
  open_in_new_tab: boolean;
  text: string; // Текст для текущей локали
  translations?: Array<{
    locale: string;
    text: string;
  }>;
  created_at: string;
  updated_at: string;
}

export interface HeroSettings {
  slide_interval: number;
  transition_effect: TransitionEffect;
  updated_at: string;
}

/**
 * Получает Hero изображения из Django API.
 */
export async function getHeroImages(): Promise<HeroImage[]> {
  try {
    // Для клиентских компонентов используем обычный fetch без next.revalidate
    // (next.revalidate работает только в Server Components)
    const response = await fetch(`${API_URL}/hero/images/`, {
      cache: 'default', // Браузер сам кеширует
    });

    if (!response.ok) {
      console.error('[Hero API] Error:', response.status);
      return [];
    }

    const data = await response.json();
    
    // Если это пагинация DRF
    if (data.results) {
      return data.results;
    }
    
    // Если это просто массив
    return Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('[Hero API] Error fetching hero images:', error);
    return [];
  }
}

/**
 * Получает кнопки Hero из Django API.
 */
export async function getHeroButtons(locale?: string): Promise<HeroButton[]> {
  try {
    const url = locale 
      ? `${API_URL}/hero/buttons/?locale=${locale}`
      : `${API_URL}/hero/buttons/`;
    
    const response = await fetch(url, {
      cache: 'default', // Браузер сам кеширует
    });

    if (!response.ok) {
      console.error('[Hero API] Error fetching buttons:', response.status);
      return [];
    }

    const data = await response.json();
    
    // Если это пагинация DRF
    if (data.results) {
      return data.results;
    }
    
    // Если это просто массив
    return Array.isArray(data) ? data : [];
  } catch (error) {
    console.error('[Hero API] Error fetching hero buttons:', error);
    return [];
  }
}

/**
 * Получает настройки Hero из Django API.
 */
export async function getHeroSettings(): Promise<HeroSettings | null> {
  try {
    // Для клиентских компонентов используем обычный fetch без next.revalidate
    const response = await fetch(`${API_URL}/hero/settings/`, {
      cache: 'default', // Браузер сам кеширует
    });

    if (!response.ok) {
      console.error('[Hero API] Error fetching settings:', response.status);
      return null;
    }

    const data = await response.json();
    
    // Если это пагинация DRF
    if (data.results && data.results.length > 0) {
      return data.results[0];
    }
    
    // Если это просто объект (ReadOnlyModelViewSet возвращает объект напрямую)
    if (data.slide_interval !== undefined) {
      return data;
    }
    
    return null;
  } catch (error) {
    console.error('[Hero API] Error fetching hero settings:', error);
    return null;
  }
}

