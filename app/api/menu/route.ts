import { NextRequest, NextResponse } from 'next/server';
import { getMenuItems } from '@/lib/menu-api';
import { defaultLocale, type Locale } from '@/lib/locales';

// Отключаем статическую генерацию для динамического API
export const dynamic = 'force-dynamic';

// Публичный API для получения меню (без авторизации)
export async function GET(request: NextRequest) {
  try {
    const url = new URL(request.url);
    const localeParam = url.searchParams.get('locale');
    const locale = (localeParam && ['en', 'es', 'ru'].includes(localeParam)) 
      ? localeParam as Locale 
      : defaultLocale;

    const items = await getMenuItems(locale);

    return NextResponse.json(items);
  } catch (error) {
    console.error('Error fetching menu:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

