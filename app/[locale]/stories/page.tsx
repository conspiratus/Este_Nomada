import Link from "next/link";
import Image from "next/image";
import { getTranslations } from 'next-intl/server';
import { getStories } from '@/lib/stories-api';
import { defaultLocale, type Locale } from '@/lib/locales';

// Включаем динамический рендеринг для получения актуальных данных
export const dynamic = 'force-dynamic';
export const revalidate = 60; // Регенерируем каждую минуту

export default async function StoriesPage({
  params: { locale: localeParam }
}: {
  params: { locale: string };
}) {
  const locale = (['en', 'es', 'ru'].includes(localeParam) ? localeParam : defaultLocale) as Locale;
  const t = await getTranslations({ locale, namespace: 'stories' });
  
  console.log(`[StoriesPage] Loading stories for locale: ${locale}`);
  const allStories = await getStories(locale);
  console.log(`[StoriesPage] Loaded ${allStories.length} stories`);
  
  if (allStories.length === 0) {
    console.warn(`[StoriesPage] No stories found for locale: ${locale}`);
  }
  
  return (
    <div className="pt-32 pb-20 min-h-screen bg-sand-50">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-4">
            {t('title')}
          </h1>
          <p className="text-lg text-charcoal-600 max-w-2xl mx-auto">
            {t('subtitle')}
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {allStories.map((story) => (
            <Link
              key={story.slug}
              href={`/${locale}/stories/${story.slug}`}
              className="bg-white rounded-lg overflow-hidden shadow-md hover:shadow-xl transition-all transform hover:scale-105 vintage-border"
            >
              {/* Cover Image */}
              <div className="aspect-video bg-gradient-to-br from-saffron-200 to-warm-400 relative overflow-hidden">
                {(story.coverImage || story.cover_image) ? (
                  <>
                    <Image
                      src={(story.coverImage || story.cover_image) as string}
                      alt={story.title}
                      fill
                      className="object-cover"
                      sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"
                      loading="lazy"
                      quality={75}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/60 via-transparent to-transparent" />
                  </>
                ) : (
                  <>
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="text-6xl">📖</span>
                    </div>
                    <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/60 via-transparent to-transparent" />
                  </>
                )}
                {story.source === "telegram" && (
                  <div className="absolute top-2 right-2 bg-saffron-500 text-white text-xs px-2 py-1 rounded-full z-10">
                    Telegram
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="p-6">
                <div className="text-sm text-saffron-600 mb-2">
                  {new Date(story.date).toLocaleDateString(locale === 'en' ? 'en-US' : locale === 'es' ? 'es-ES' : 'ru-RU', {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </div>
                <h3 className="text-xl font-semibold text-charcoal-900 mb-3 line-clamp-2">
                  {story.title}
                </h3>
                <p className="text-charcoal-600 text-sm line-clamp-3">
                  {story.excerpt}
                </p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}

