"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { X, ChevronLeft, ChevronRight } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { useLocale, useTranslations } from 'next-intl';

interface MenuItemImage {
  id: number;
  image_url: string;
  order: number;
}

interface MenuItemAttribute {
  id: number;
  locale: string;
  name: string;
  value: string;
  order: number;
}

interface RelatedStory {
  id: number;
  title: string;
  slug: string;
  excerpt: string | null;
  coverImage: string | null;
  date: string;
}

interface MenuItem {
  id: number;
  name: string;
  description: string | null;
  category: string;
  price: number | null;
  image: string | null;
  images?: MenuItemImage[];
  attributes?: MenuItemAttribute[];
  related_stories?: RelatedStory[];
  order: number;
  active: boolean;
}

interface MenuItemModalProps {
  item: MenuItem | null;
  isOpen: boolean;
  onClose: () => void;
}

export default function MenuItemModal({ item, isOpen, onClose }: MenuItemModalProps) {
  const locale = useLocale();
  const t = useTranslations('menu');
  const [currentImageIndex, setCurrentImageIndex] = useState(0);

  // Получаем все изображения: сначала из images, потом fallback на image
  const allImages = item
    ? item.images && item.images.length > 0
      ? item.images.map(img => img.image_url)
      : item.image
        ? [item.image]
        : []
    : [];

  useEffect(() => {
    if (isOpen && item) {
      setCurrentImageIndex(0);
      // Блокируем скролл страницы при открытии модального окна
      document.body.style.overflow = 'hidden';
      
      // Логируем данные для отладки
      console.log('[MenuItemModal] Item data:', {
        id: item.id,
        name: item.name,
        hasRelatedStories: !!item.related_stories,
        relatedStoriesCount: item.related_stories?.length || 0,
        relatedStories: item.related_stories,
      });
    } else {
      // Разблокируем скролл при закрытии
      document.body.style.overflow = 'unset';
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, item]);

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    if (isOpen) {
      window.addEventListener('keydown', handleEscape);
    }

    return () => {
      window.removeEventListener('keydown', handleEscape);
    };
  }, [isOpen, onClose]);

  const nextImage = () => {
    if (allImages.length > 0) {
      setCurrentImageIndex((prev) => (prev + 1) % allImages.length);
    }
  };

  const prevImage = () => {
    if (allImages.length > 0) {
      setCurrentImageIndex((prev) => (prev - 1 + allImages.length) % allImages.length);
    }
  };

  if (!item || !isOpen) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop - клик вне модального окна закрывает его */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm z-50"
            aria-label="Close modal on backdrop click"
          />

          {/* Modal - предотвращаем закрытие при клике внутри модального окна */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ type: "spring", duration: 0.3 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none"
            onClick={(e) => e.stopPropagation()}
          >
            <div 
              className="bg-white rounded-2xl shadow-2xl max-w-6xl w-full max-h-[90vh] overflow-hidden flex flex-col md:flex-row pointer-events-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Left: Images */}
              <div className="relative w-full md:w-1/2 h-64 md:h-auto bg-gradient-to-br from-saffron-200 to-warm-400">
                {allImages.length > 0 ? (
                  <>
                    {/* Main Image */}
                    <div className="relative w-full h-full">
                      <Image
                        src={allImages[currentImageIndex]}
                        alt={item.name}
                        fill
                        className="object-cover"
                        sizes="(max-width: 768px) 100vw, 50vw"
                        loading="eager"
                        quality={80}
                      />
                    </div>

                    {/* Navigation Arrows */}
                    {allImages.length > 1 && (
                      <>
                        <button
                          onClick={prevImage}
                          className="absolute left-4 top-1/2 -translate-y-1/2 bg-white/80 hover:bg-white rounded-full p-2 shadow-lg transition-all z-10"
                          aria-label="Previous image"
                        >
                          <ChevronLeft className="w-6 h-6 text-charcoal-900" />
                        </button>
                        <button
                          onClick={nextImage}
                          className="absolute right-4 top-1/2 -translate-y-1/2 bg-white/80 hover:bg-white rounded-full p-2 shadow-lg transition-all z-10"
                          aria-label="Next image"
                        >
                          <ChevronRight className="w-6 h-6 text-charcoal-900" />
                        </button>
                      </>
                    )}

                    {/* Image Indicators */}
                    {allImages.length > 1 && (
                      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2 z-10">
                        {allImages.map((_, index) => (
                          <button
                            key={index}
                            onClick={() => setCurrentImageIndex(index)}
                            className={`w-2 h-2 rounded-full transition-all ${
                              index === currentImageIndex
                                ? 'bg-white w-6'
                                : 'bg-white/50 hover:bg-white/75'
                            }`}
                            aria-label={`Go to image ${index + 1}`}
                          />
                        ))}
                      </div>
                    )}
                  </>
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <span className="text-8xl">🍲</span>
                  </div>
                )}
              </div>

              {/* Right: Content */}
              <div className="w-full md:w-1/2 p-6 md:p-8 overflow-y-auto relative">
                {/* Close Button - всегда фиксированная позиция, не скролится */}
                <button
                  onClick={onClose}
                  className="fixed top-4 right-4 bg-white/90 hover:bg-white rounded-full p-2 shadow-lg transition-all z-[60]"
                  aria-label="Close modal"
                >
                  <X className="w-5 h-5 text-charcoal-900" />
                </button>

                {/* Category */}
                <div className="mb-4">
                  <span className="inline-block px-3 py-1 bg-saffron-100 text-saffron-700 rounded-full text-sm font-medium">
                    {item.category}
                  </span>
                </div>

                {/* Title */}
                <h2 className="text-3xl md:text-4xl font-bold text-charcoal-900 mb-4">
                  {item.name}
                </h2>

                {/* Price */}
                {item.price && (
                  <div className="mb-6">
                    <span className="text-2xl font-semibold text-saffron-600">
                      {item.price}€
                    </span>
                  </div>
                )}

                {/* Description */}
                {item.description && (
                  <div 
                    className="mb-6 text-charcoal-700 leading-relaxed prose prose-lg max-w-none prose-p:text-charcoal-700 prose-strong:text-charcoal-900 prose-a:text-saffron-600"
                    dangerouslySetInnerHTML={{ __html: item.description }}
                  />
                )}

                {/* Attributes */}
                {item.attributes && item.attributes.length > 0 && (
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-charcoal-900 mb-3">
                      {t('attributes')}
                    </h3>
                    <div className="space-y-2">
                      {item.attributes
                        .sort((a, b) => a.order - b.order)
                        .map((attr) => (
                          <div
                            key={attr.id}
                            className="flex items-center justify-between py-2 border-b border-charcoal-100 last:border-0"
                          >
                            <span className="text-sm font-medium text-charcoal-600">
                              {attr.name}:
                            </span>
                            <span className="text-sm text-charcoal-900">
                              {attr.value}
                            </span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}

                {/* Thumbnail Images (if multiple) */}
                {allImages.length > 1 && (
                  <div className="mt-6 pt-6 border-t border-charcoal-200">
                    <p className="text-sm text-charcoal-600 mb-3">{t('otherImages')}:</p>
                    <div className="flex gap-2 overflow-x-auto">
                      {allImages.map((imageUrl, index) => (
                        <button
                          key={index}
                          onClick={() => setCurrentImageIndex(index)}
                          className={`relative w-20 h-20 rounded-lg overflow-hidden flex-shrink-0 border-2 transition-all ${
                            index === currentImageIndex
                              ? 'border-saffron-500'
                              : 'border-transparent hover:border-charcoal-300'
                          }`}
                        >
                          <Image
                            src={imageUrl}
                            alt={`${item.name} - изображение ${index + 1}`}
                            fill
                            className="object-cover"
                            sizes="80px"
                            quality={70}
                          />
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Related Stories */}
                {item.related_stories && item.related_stories.length > 0 && (
                  <div className="mt-8 pt-6 border-t border-charcoal-200">
                    <h3 className="text-lg font-semibold text-charcoal-900 mb-4">
                      {t('relatedStories') || 'Связанные истории'}
                    </h3>
                    <div className="grid grid-cols-1 gap-4">
                      {item.related_stories.map((story) => (
                        <Link
                          key={story.id}
                          href={`/${locale}/stories/${story.slug}`}
                          className="flex gap-4 p-3 bg-sand-50 rounded-lg hover:bg-sand-100 transition-colors group"
                          onClick={onClose}
                        >
                          {/* Story Cover */}
                          <div className="relative w-20 h-20 flex-shrink-0 rounded-lg overflow-hidden">
                            {story.coverImage ? (
                              <Image
                                src={story.coverImage}
                                alt={story.title}
                                fill
                                className="object-cover"
                                sizes="80px"
                                quality={70}
                              />
                            ) : (
                              <div className="w-full h-full bg-gradient-to-br from-saffron-200 to-warm-400 flex items-center justify-center">
                                <span className="text-2xl">📖</span>
                              </div>
                            )}
                          </div>
                          {/* Story Info */}
                          <div className="flex-1 min-w-0">
                            <h4 className="text-sm font-semibold text-charcoal-900 mb-1 line-clamp-1 group-hover:text-saffron-600 transition-colors">
                              {story.title}
                            </h4>
                            {story.excerpt && (
                              <p className="text-xs text-charcoal-600 line-clamp-2">
                                {story.excerpt}
                              </p>
                            )}
                            <div className="text-xs text-saffron-600 mt-1">
                              {new Date(story.date).toLocaleDateString(locale === 'en' ? 'en-US' : locale === 'es' ? 'es-ES' : 'ru-RU', {
                                year: "numeric",
                                month: "short",
                                day: "numeric",
                              })}
                            </div>
                          </div>
                        </Link>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

