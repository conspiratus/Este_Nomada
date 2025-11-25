import createMiddleware from 'next-intl/middleware';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { locales, defaultLocale } from './lib/locales';

const intlMiddleware = createMiddleware({
  locales,
  defaultLocale,
  localePrefix: 'always',
  // Сохраняем выбранную локаль в куки
  localeDetection: true
});

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Пропускаем статические файлы и файлы с расширениями
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname.startsWith('/favicon') ||
    pathname.startsWith('/icon') ||
    pathname.match(/\.(ico|png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|eot|css|js|json)$/i)
  ) {
    return NextResponse.next();
  }

  // Проверяем куку с сохраненной локалью для редиректа на корневой путь
  const savedLocale = request.cookies.get('NEXT_LOCALE')?.value;
  if (savedLocale && locales.includes(savedLocale as any)) {
    // Если пользователь заходит на корневой путь, редиректим на сохраненную локаль
    if (pathname === '/' || pathname === '') {
      const url = request.nextUrl.clone();
      url.pathname = `/${savedLocale}`;
      return NextResponse.redirect(url);
    }
  }

  // Применяем i18n middleware для всех остальных маршрутов
  const response = intlMiddleware(request);
  
  // Убеждаемся, что кука с локалью установлена
  const locale = request.nextUrl.pathname.split('/')[1];
  if (locales.includes(locale as any)) {
    response.cookies.set('NEXT_LOCALE', locale, {
      path: '/',
      maxAge: 60 * 60 * 24 * 365, // 1 год
      sameSite: 'lax'
    });
  }
  
  return response;
}

export const config = {
  matcher: [
    '/((?!api|_next|_vercel|.*\\..*).*)'
  ],
};
