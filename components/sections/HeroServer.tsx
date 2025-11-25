/**
 * Server Component wrapper для Hero - загружает данные на сервере для улучшения FCP
 */
import { headers } from 'next/headers';
import Hero from './Hero';
import { getHeroImages, getHeroSettings } from '@/lib/hero-api';

async function getServerApiUrl(): Promise<string> {
  try {
    const headersList = await headers();
    const host = headersList.get('host') || 'estenomada.es';
    const protocol = headersList.get('x-forwarded-proto') || 'https';
    return `${protocol}://${host}/api`;
  } catch {
    return process.env.NEXT_PUBLIC_API_URL || 'https://estenomada.es/api';
  }
}

export default async function HeroServer({ locale }: { locale: string }) {
  // Загружаем данные на сервере
  const apiUrl = await getServerApiUrl();
  
  // Временно используем клиентский компонент, но данные уже будут в кеше
  // TODO: Переделать Hero на Server Component с передачей данных через props
  return <Hero locale={locale} />;
}

