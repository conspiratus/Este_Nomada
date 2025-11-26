import { notFound } from "next/navigation";
import Link from "next/link";
import { Post } from "@/types/post";
import { getStoryBySlug } from "@/lib/stories-api";
import { defaultLocale } from "@/lib/locales";

async function fetchStory(slug: string): Promise<Post | null> {
  try {
    const story = await getStoryBySlug(defaultLocale, slug);
    if (!story) return null;
    return {
      ...story,
      coverImage: story.cover_image || story.coverImage,
    } as Post;
  } catch (error) {
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
    slug: string;
  };
}

// Генерируем статические пути для всех статей
export async function generateStaticParams() {
  try {
    const { getStories } = await import('@/lib/stories-api');
    const stories = await getStories();
    if (stories.length === 0) {
      return Object.keys(fallbackStories).map((slug) => ({ slug }));
    }
    return stories.map((story) => ({ slug: story.slug }));
  } catch (error) {
    return Object.keys(fallbackStories).map((slug) => ({ slug }));
  }
}

export default async function StoryPage({ params }: StoryPageProps) {
  const story = await fetchStory(params.slug) || fallbackStories[params.slug];

  if (!story) {
    notFound();
  }

  return (
    <article className="pt-32 pb-20 min-h-screen bg-sand-50">
      <div className="container mx-auto px-4 max-w-4xl">
        {/* Back Link */}
        <Link
          href="/stories"
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
          Назад к историям
        </Link>

        {/* Cover Image */}
        <div className="aspect-video bg-gradient-to-br from-saffron-200 to-warm-400 rounded-lg overflow-hidden mb-8 relative">
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-8xl">📖</span>
          </div>
          <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/40 via-transparent to-transparent" />
          {story.source === "telegram" && (
            <div className="absolute top-4 right-4 bg-saffron-500 text-white text-sm px-3 py-1 rounded-full">
              Telegram
            </div>
          )}
        </div>

        {/* Content */}
        <div className="bg-white rounded-lg p-8 md:p-12 shadow-lg vintage-border">
          <div className="text-sm text-saffron-600 mb-4">
            {new Date(story.date).toLocaleDateString("ru-RU", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })}
          </div>
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-8">
            {story.title}
          </h1>
          <div className="prose prose-lg max-w-none prose-headings:text-charcoal-900 prose-p:text-charcoal-700 prose-a:text-saffron-600 prose-strong:text-charcoal-900">
            {story.content.split("\n\n").map((paragraph, index) => {
              const key = `${story.slug}-${index}`;
              if (paragraph.startsWith("# ")) {
                return (
                  <h2 key={key} className="text-3xl font-bold text-charcoal-900 mt-8 mb-4">
                    {paragraph.replace("# ", "")}
                  </h2>
                );
              }
              if (paragraph.startsWith("## ")) {
                return (
                  <h3 key={key} className="text-2xl font-semibold text-charcoal-900 mt-6 mb-3">
                    {paragraph.replace("## ", "")}
                  </h3>
                );
              }
              return (
                <p key={key} className="mb-4 leading-relaxed text-charcoal-700">
                  {paragraph}
                </p>
              );
            })}
          </div>
        </div>
      </div>
    </article>
  );
}

