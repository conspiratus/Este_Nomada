import { query } from './db';
import { type Locale } from '@/lib/locales';

export interface StoryTranslation {
  id: number;
  story_id: number;
  locale: string;
  title: string;
  slug: string;
  excerpt: string | null;
  content: string;
}

export interface Story {
  id: number;
  date: string;
  cover_image: string | null;
  source: 'manual' | 'telegram';
  published: boolean;
  // Переводы
  title: string;
  slug: string;
  excerpt: string | null;
  content: string;
}

/**
 * Получает истории для указанной локали
 */
export async function getStories(
  locale: Locale,
  limit?: number,
  offset?: number
): Promise<Story[]> {
  try {
    let sql = `SELECT 
      s.id,
      s.date,
      s.cover_image,
      s.source,
      s.published,
      COALESCE(st.title, s.title) as title,
      COALESCE(st.slug, s.slug) as slug,
      COALESCE(st.excerpt, s.excerpt) as excerpt,
      COALESCE(st.content, s.content) as content
    FROM stories s
    LEFT JOIN story_translations st ON s.id = st.story_id AND st.locale = ?
    WHERE s.published = TRUE
    ORDER BY s.date DESC, s.created_at DESC`;

    const params: any[] = [locale];

    if (limit) {
      sql += ` LIMIT ?`;
      params.push(limit);
      
      if (offset) {
        sql += ` OFFSET ?`;
        params.push(offset);
      }
    }

    const stories = await query<any[]>(sql, params);

    return stories.map(story => ({
      id: story.id,
      date: story.date,
      cover_image: story.cover_image,
      source: story.source,
      published: story.published,
      title: story.title || '',
      slug: story.slug || '',
      excerpt: story.excerpt,
      content: story.content || '',
    }));
  } catch (error) {
    console.error('[Stories] Error fetching stories:', error);
    return [];
  }
}

/**
 * Получает историю по slug для указанной локали
 */
export async function getStoryBySlug(locale: Locale, slug: string): Promise<Story | null> {
  try {
    const stories = await query<any[]>(
      `SELECT 
        s.id,
        s.date,
        s.cover_image,
        s.source,
        s.published,
        COALESCE(st.title, s.title) as title,
        COALESCE(st.slug, s.slug) as slug,
        COALESCE(st.excerpt, s.excerpt) as excerpt,
        COALESCE(st.content, s.content) as content
      FROM stories s
      LEFT JOIN story_translations st ON s.id = st.story_id AND st.locale = ?
      WHERE (st.slug = ? OR s.slug = ?) AND s.published = TRUE
      LIMIT 1`,
      [locale, slug, slug]
    );

    if (stories.length === 0) {
      return null;
    }

    const story = stories[0];
    return {
      id: story.id,
      date: story.date,
      cover_image: story.cover_image,
      source: story.source,
      published: story.published,
      title: story.title || '',
      slug: story.slug || '',
      excerpt: story.excerpt,
      content: story.content || '',
    };
  } catch (error) {
    console.error('[Stories] Error fetching story by slug:', error);
    return null;
  }
}

/**
 * Сохраняет перевод истории
 */
export async function saveStoryTranslation(
  storyId: number,
  locale: Locale,
  title: string,
  slug: string,
  excerpt: string | null,
  content: string
): Promise<void> {
  await query(
    `INSERT INTO story_translations (story_id, locale, title, slug, excerpt, content)
     VALUES (?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
       title = VALUES(title),
       slug = VALUES(slug),
       excerpt = VALUES(excerpt),
       content = VALUES(content),
       updated_at = CURRENT_TIMESTAMP`,
    [storyId, locale, title, slug, excerpt, content]
  );
}

