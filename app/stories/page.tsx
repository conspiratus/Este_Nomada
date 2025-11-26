import Link from "next/link";
import { Post } from "@/types/post";
import { getStories } from "@/lib/stories-api";

async function fetchStories(): Promise<Post[]> {
  try {
    const stories = await getStories();
    return stories
      .filter(story => story && story.id) // Фильтруем только валидные истории
      .map(story => ({
        ...story,
        id: story.id, // Убеждаемся, что ID передается
        coverImage: story.cover_image || story.coverImage,
      })) as Post[];
  } catch (error) {
    return [];
  }
}

export default async function StoriesPage() {
  const allStories = await fetchStories();
  return (
    <div className="pt-32 pb-20 min-h-screen bg-sand-50">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-4">
            Истории в пути
          </h1>
          <p className="text-lg text-charcoal-600 max-w-2xl mx-auto">
            Истории о нашем пути, блюдах и людях, которые встречаются на дороге
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {allStories.map((story) => (
            <Link
              key={story.id || story.slug}
              href={`/stories/${story.slug}`}
              className="bg-white rounded-lg overflow-hidden shadow-md hover:shadow-xl transition-all transform hover:scale-105 vintage-border"
            >
              {/* Cover Image */}
              <div className="aspect-video bg-gradient-to-br from-saffron-200 to-warm-400 relative overflow-hidden">
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="text-6xl">📖</span>
                </div>
                <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/60 via-transparent to-transparent" />
                {story.source === "telegram" && (
                  <div className="absolute top-2 right-2 bg-saffron-500 text-white text-xs px-2 py-1 rounded-full">
                    Telegram
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="p-6">
                <div className="text-sm text-saffron-600 mb-2">
                  {new Date(story.date).toLocaleDateString("ru-RU", {
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

