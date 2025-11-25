import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { Post } from "@/types/post";
import { getStoryBySlug } from "@/lib/stories-api";
import { defaultLocale, locales, type Locale } from "@/lib/locales";
import { getTranslations } from 'next-intl/server';

async function fetchStory(locale: Locale, slug: string): Promise<Post | null> {
  try {
    const story = await getStoryBySlug(locale, slug);
    if (!story) return null;
    
    // Убеждаемся, что все поля корректны
    return {
      ...story,
      coverImage: story.cover_image || story.coverImage || null,
      title: story.title || 'Untitled Story',
      content: story.content || '',
      date: story.date || new Date().toISOString().split('T')[0],
    } as Post;
  } catch (error) {
    console.error('[StoryPage] Error fetching story:', error);
    return null;
  }
}

// Временные данные для fallback (если БД ещё не инициализирована)
const fallbackStories: Record<string, Post> = {
  "pervyj-koster": {
    title: "Первый костёр на пути",
    slug: "pervyj-koster",
    date: "2024-01-15",
    excerpt: "История о том, как всё начиналось — первый костёр, первый плов, первые встречи.",
    coverImage: "/stories/koster.jpg",
    content: `# Первый костёр на пути

Это была холодная ночь в горах. Ветер свистел между скалами, а звёзды сияли так ярко, что казалось, можно дотянуться до них рукой.

Именно тогда, у первого костра, родилась идея Este Nómada. Не план, не бизнес-модель, а просто желание поделиться тем, что у нас есть — теплом, едой, историями.

Первый плов, приготовленный на том костре, был не идеальным. Но он был настоящим. И именно это — настоящесть, искренность — мы хотим нести дальше.

Каждое блюдо, которое мы готовим сегодня, несёт в себе тепло того первого костра.`,
    source: "manual",
  },
  "recept-cherez-pokoleniya": {
    title: "Рецепт, переданный через поколения",
    slug: "recept-cherez-pokoleniya",
    date: "2024-02-20",
    excerpt: "Как секреты приготовления плова передавались от деда к отцу, от отца к сыну.",
    coverImage: "/stories/recept.jpg",
    content: `# Рецепт, переданный через поколения

Рецепт плова — это не просто список ингредиентов. Это история семьи, передаваемая из поколения в поколение.

Мой дед учил моего отца не только пропорциям, но и чувству огня, пониманию момента, когда рис готов, а мясо достигло нужной консистенции.

Теперь я передаю это знание дальше. Каждый раз, когда я готовлю плов, я чувствую связь с теми, кто был до меня.

Это не просто еда. Это традиция, живущая в каждом зерне риса, в каждом кусочке мяса.`,
    source: "manual",
  },
  "doroga-v-asturiyu": {
    title: "Дорога в Астурию",
    slug: "doroga-v-asturiyu",
    date: "2024-03-10",
    excerpt: "Путешествие, которое привело нас в Астурию, и как мы решили поделиться нашей кухней.",
    coverImage: "/stories/doroga.jpg",
    content: `# Дорога в Астурию

Путь в Астурию был долгим. Через горы, через долины, через города и деревни.

И когда мы приехали сюда, мы поняли — это место, где мы можем поделиться нашей кухней, нашими историями.

Астурия приняла нас тепло. И мы хотим ответить тем же — теплом наших блюд, искренностью наших историй.

Este Nómada — это не просто проект. Это продолжение пути, который начался много лет назад, у того первого костра.`,
    source: "manual",
  },
};

interface StoryPageProps {
  params: {
    locale: string;
    slug: string;
  };
}

// Отключаем статическую генерацию для динамических маршрутов
export const dynamic = 'force-dynamic';
export const revalidate = 300; // ISR: регенерируем каждые 5 минут

// Генерируем статические пути для всех статей (опционально, для предварительной генерации)
export async function generateStaticParams() {
  const { locales } = await import('@/lib/locales');
  try {
    const { getStories } = await import('@/lib/stories-api');
    const stories = await getStories();
    const slugs = stories.length > 0 
      ? stories.map((story) => story.slug)
      : Object.keys(fallbackStories);
    
    // Генерируем пути для всех локалей и всех историй
    return locales.flatMap((locale) =>
      slugs.map((slug) => ({ locale, slug }))
    );
  } catch (error) {
    // Fallback: возвращаем пути для всех локалей с fallback историями
    const slugs = Object.keys(fallbackStories);
    return locales.flatMap((locale) =>
      slugs.map((slug) => ({ locale, slug }))
    );
  }
}

export default async function StoryPage({ params }: StoryPageProps) {
  const locale = (['en', 'es', 'ru'].includes(params.locale) ? params.locale : defaultLocale) as Locale;
  const t = await getTranslations({ locale, namespace: 'stories' });
  
  const story = await fetchStory(locale, params.slug) || fallbackStories[params.slug];

  if (!story) {
    notFound();
  }

  return (
    <article className="pt-32 pb-20 min-h-screen bg-sand-50">
      <div className="container mx-auto px-4 max-w-4xl">
        {/* Back Link */}
        <Link
          href={`/${locale}/stories`}
          className="inline-flex items-center text-saffron-600 hover:text-saffron-700 mb-8 transition-colors"
        >
          <svg
            className="w-5 h-5 mr-2"
            fill="none"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path d="M15 19l-7-7 7-7" />
          </svg>
          {t('allStories') || 'Назад к историям'}
        </Link>

        {/* Cover Image */}
        <div className="aspect-video bg-gradient-to-br from-saffron-200 to-warm-400 rounded-lg overflow-hidden mb-8 relative">
          {(() => {
            const coverImageUrl = story.coverImage || story.cover_image;
            if (coverImageUrl && typeof coverImageUrl === 'string' && coverImageUrl.trim() !== '') {
              try {
                return (
                  <>
                    <Image
                      src={coverImageUrl}
                      alt={story.title || 'Story cover'}
                      fill
                      className="object-cover"
                      sizes="(max-width: 768px) 100vw, (max-width: 1024px) 80vw, 1200px"
                      priority
                      quality={80}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/40 via-transparent to-transparent" />
                  </>
                );
              } catch (error) {
                console.error('[StoryPage] Error rendering cover image:', error);
              }
            }
            return (
              <>
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="text-8xl">📖</span>
                </div>
                <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/40 via-transparent to-transparent" />
              </>
            );
          })()}
          {story.source === "telegram" && (
            <div className="absolute top-4 right-4 bg-saffron-500 text-white text-sm px-3 py-1 rounded-full z-10">
              Telegram
            </div>
          )}
        </div>

        {/* Content */}
        <div className="bg-white rounded-lg p-8 md:p-12 shadow-lg vintage-border">
          <div className="text-sm text-saffron-600 mb-4">
            {new Date(story.date).toLocaleDateString(
              locale === 'en' ? 'en-US' : locale === 'es' ? 'es-ES' : 'ru-RU',
              {
                year: "numeric",
                month: "long",
                day: "numeric",
              }
            )}
          </div>
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-8">
            {story.title || 'Untitled Story'}
          </h1>
          {/* Content with HTML support */}
          {story.content && typeof story.content === 'string' && story.content.trim() !== '' ? (
            <div 
              className="prose prose-lg max-w-none prose-headings:text-charcoal-900 prose-p:text-charcoal-700 prose-a:text-saffron-600 prose-strong:text-charcoal-900 prose-ul:text-charcoal-700 prose-li:text-charcoal-700 prose-h2:text-3xl prose-h2:font-bold prose-h2:mt-8 prose-h2:mb-4 prose-h3:text-2xl prose-h3:font-semibold prose-h3:mt-6 prose-h3:mb-3"
              dangerouslySetInnerHTML={{ __html: story.content }}
            />
          ) : (
            <p className="text-charcoal-600">No content available.</p>
          )}
        </div>
      </div>
    </article>
  );
}

