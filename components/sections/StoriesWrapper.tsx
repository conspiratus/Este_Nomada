import Stories from './Stories';
import { getStories } from '@/lib/stories-api';
import { defaultLocale, type Locale } from '@/lib/locales';
import { Post } from '@/types/post';

interface StoriesWrapperProps {
  locale?: Locale;
}

export default async function StoriesWrapper({ locale = defaultLocale }: StoriesWrapperProps) {
  console.log(`[StoriesWrapper] Loading featured stories for locale: ${locale}`);
  const featuredStories = await getStories(locale, 3);
  console.log(`[StoriesWrapper] Loaded ${featuredStories.length} stories from API`);
  
  // Преобразуем cover_image в coverImage для совместимости
  const formattedStories: Post[] = featuredStories
    .filter(story => story && story.id) // Фильтруем только валидные истории с ID
    .map(story => {
      const { cover_image, excerpt, ...rest } = story;
      return {
        ...rest,
        id: story.id, // Убеждаемся, что ID передается
        coverImage: cover_image || story.coverImage || undefined,
        excerpt: excerpt || undefined,
      } as Post;
    });
  
  console.log(`[StoriesWrapper] Formatted ${formattedStories.length} stories for display`);
  
  if (formattedStories.length === 0) {
    console.warn(`[StoriesWrapper] No stories to display for locale: ${locale}`);
  }
  
  return <Stories stories={formattedStories} />;
}

