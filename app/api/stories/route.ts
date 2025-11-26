import { NextRequest, NextResponse } from 'next/server';
import { getStories } from '@/lib/stories-multilang';
import { defaultLocale, type Locale } from '@/lib/locales';

// Отключаем статическую генерацию для динамического API
export const dynamic = 'force-dynamic';

// Публичный API для получения историй (без авторизации)
export async function GET(request: NextRequest) {
  try {
    const url = new URL(request.url);
    const { searchParams } = url;
    const localeParam = searchParams.get('locale');
    const locale = (localeParam && ['en', 'es', 'ru'].includes(localeParam)) 
      ? localeParam as Locale 
      : defaultLocale;
    
    const limit = searchParams.get('limit') ? parseInt(searchParams.get('limit')!) : undefined;
    const offset = searchParams.get('offset') ? parseInt(searchParams.get('offset')!) : undefined;

    const stories = await getStories(locale, limit, offset);

    // Преобразуем cover_image в coverImage для совместимости
    const formattedStories = stories.map(story => ({
      ...story,
      coverImage: story.cover_image || undefined,
    }));

    return NextResponse.json(formattedStories);
  } catch (error) {
    console.error('Error fetching stories:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

