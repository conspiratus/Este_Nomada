import { NextRequest, NextResponse } from 'next/server';
import { query } from '@/lib/db';
import { Post } from '@/types/post';
import { notFound } from 'next/navigation';

// Публичный API для получения истории по slug
export async function GET(
  request: NextRequest,
  { params }: { params: { slug: string } }
) {
  try {
    const stories = await query<Post[]>(
      'SELECT * FROM stories WHERE slug = ? AND published = TRUE',
      [params.slug]
    );

    if (stories.length === 0) {
      return NextResponse.json(
        { error: 'Story not found' },
        { status: 404 }
      );
    }

    const story = stories[0];
    
    // Преобразуем cover_image в coverImage
    const formattedStory = {
      ...story,
      coverImage: story.cover_image || story.coverImage,
    };

    return NextResponse.json(formattedStory);
  } catch (error) {
    console.error('Error fetching story:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}



