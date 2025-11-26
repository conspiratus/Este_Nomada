"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import Image from "next/image";
import { useTranslations, useLocale } from 'next-intl';
import { Post } from "@/types/post";

interface StoriesProps {
  stories: Post[];
}

export default function Stories({ stories: featuredStories }: StoriesProps) {
  const t = useTranslations('stories');
  const locale = useLocale();
  
  // Фильтруем пустые истории и используем стабильные ключи
  const validStories = featuredStories.filter(story => story && (story.id || story.slug));
  
  return (
    <section className="py-20 bg-gradient-to-b from-white to-sand-50">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-4">
            {t('title')}
          </h2>
          <p className="text-lg text-charcoal-600 max-w-2xl mx-auto">
            {t('subtitle')}
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-8">
          {validStories.map((story, index) => (
            <motion.article
              key={story.id || story.slug}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="bg-white rounded-lg overflow-hidden shadow-md hover:shadow-xl transition-all transform hover:scale-105 vintage-border"
            >
              <Link href={`/${locale}/stories/${story.slug}`}>
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
            </motion.article>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="text-center"
        >
          <Link
            href={`/${locale}/stories`}
            className="inline-block px-8 py-3 bg-transparent border-2 border-saffron-500 text-saffron-600 rounded-full hover:bg-saffron-50 transition-all font-medium"
          >
            {t('allStories')}
          </Link>
        </motion.div>
      </div>
    </section>
  );
}

