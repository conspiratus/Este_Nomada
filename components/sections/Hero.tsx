"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useTranslations, useLocale } from 'next-intl';
import Image from "next/image";
import Link from "next/link";
import { getHeroImages, getHeroSettings, type HeroImage, type HeroSettings, type TransitionEffect } from '@/lib/hero-api';

interface HeroProps {
  locale?: string;
}

interface SiteSettings {
  site_name: string;
  logo_url: string | null;
}

export default function Hero({ locale: localeProp }: HeroProps = {}) {
  const t = useTranslations('hero');
  const locale = useLocale();
  const [images, setImages] = useState<HeroImage[]>([]);
  const [settings, setSettings] = useState<HeroSettings | null>(null);
  const [siteSettings, setSiteSettings] = useState<SiteSettings>({
    site_name: 'Este Nómada',
    logo_url: null,
  });
  const [currentIndex, setCurrentIndex] = useState(0);
  const [loading, setLoading] = useState(true);

  // Загружаем настройки сайта
  useEffect(() => {
    const fetchSiteSettings = async () => {
      try {
        const response = await fetch('/api/settings/public/');
        const data = await response.json();
        setSiteSettings({
          site_name: data.site_name || 'Este Nómada',
          logo_url: data.logo_url || null,
        });
      } catch (error) {
        console.error('[Hero] Error fetching site settings:', error);
      }
    };
    fetchSiteSettings();
  }, []);

  // Загружаем изображения и настройки
  useEffect(() => {
    const loadHeroData = async () => {
      try {
        setLoading(true);
        const [heroImages, heroSettings] = await Promise.all([
          getHeroImages(),
          getHeroSettings(),
        ]);
        
        // Сортируем изображения по order
        const sortedImages = heroImages.sort((a, b) => a.order - b.order);
        setImages(sortedImages);
        setSettings(heroSettings);
      } catch (error) {
        console.error('Error loading hero data:', error);
      } finally {
        setLoading(false);
      }
    };

    loadHeroData();
  }, []);

  // Автоматическое переключение слайдов
  useEffect(() => {
    if (images.length <= 1) return;

    const interval = settings?.slide_interval || 5000;
    const timer = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % images.length);
    }, interval);

    return () => clearInterval(timer);
  }, [images.length, settings?.slide_interval]);

  // Если нет изображений, используем градиент
  if (loading || images.length === 0) {
    return (
      <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
        <div className="absolute inset-0 z-0">
          <div className="absolute inset-0 bg-gradient-to-b from-saffron-200 via-warm-300 to-charcoal-800" />
          <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/60 via-transparent to-transparent" />
        </div>

        {/* Content */}
        <div className="relative z-10 container mx-auto px-4 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="max-w-4xl mx-auto"
          >
          {/* Logo */}
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="mb-8"
          >
            <div className="inline-flex items-center justify-center w-32 h-32 mb-3 shadow-2xl rounded-full overflow-hidden bg-saffron-500">
              {siteSettings.logo_url ? (
                <img
                  src={siteSettings.logo_url}
                  alt={siteSettings.site_name}
                  width={128}
                  height={128}
                  className="object-cover rounded-full"
                  style={{ width: '128px', height: '128px' }}
                />
              ) : (
                <span className="text-white text-6xl">EN</span>
              )}
            </div>
          </motion.div>
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.8 }}
              className="text-xl md:text-2xl text-sand-100 mb-10 font-light"
            >
              {t('subtitle')}
            </motion.p>

            {/* Buttons */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 1 }}
              className="flex flex-col sm:flex-row gap-4 justify-center"
            >
              <Link
                href={`/${locale}/stories`}
                className="px-8 py-4 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-all font-medium text-lg shadow-lg hover:shadow-xl transform hover:scale-105"
              >
                {t('readMore')}
              </Link>
              <a
                href="https://t.me/este_nomada"
                target="_blank"
                rel="noopener noreferrer"
                className="px-8 py-4 bg-transparent border-2 border-white text-white rounded-full hover:bg-white/10 transition-all font-medium text-lg"
              >
                {t('telegramChannel')}
              </a>
            </motion.div>
          </motion.div>
        </div>
      </section>
    );
  }

  // Получаем эффект перехода из настроек
  const transitionEffect = settings?.transition_effect || 'crossfade';
  
  // Определяем параметры анимации в зависимости от эффекта
  const getAnimationProps = (effect: TransitionEffect) => {
    switch (effect) {
      case 'crossfade':
        return {
          mode: 'sync' as const, // Одновременное появление/исчезновение
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          exit: { opacity: 0 },
          transition: { duration: 1, ease: 'easeInOut' }
        };
      case 'fade':
        return {
          mode: 'wait' as const, // Ждем исчезновения перед появлением
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          exit: { opacity: 0 },
          transition: { duration: 0.5 }
        };
      case 'slide':
        return {
          mode: 'wait' as const,
          initial: { x: '100%', opacity: 0 },
          animate: { x: 0, opacity: 1 },
          exit: { x: '-100%', opacity: 0 },
          transition: { duration: 0.7, ease: 'easeInOut' }
        };
      default:
        return {
          mode: 'sync' as const,
          initial: { opacity: 0 },
          animate: { opacity: 1 },
          exit: { opacity: 0 },
          transition: { duration: 1 }
        };
    }
  };

  const animProps = getAnimationProps(transitionEffect);

  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* Background Images with Carousel */}
      <div className="absolute inset-0 z-0">
        <AnimatePresence mode={animProps.mode}>
          {images.map((image, index) => {
            if (index !== currentIndex) return null;
            
            // Преобразуем URL: если это localhost:3000, используем относительный путь
            let imageSrc = image.image_url;
            try {
              const url = new URL(image.image_url);
              if (url.hostname === 'localhost' && url.port === '3000') {
                imageSrc = url.pathname; // Используем относительный путь для файлов из public/
              }
            } catch (e) {
              // Если это не валидный URL, используем как есть (относительный путь)
              if (!image.image_url.startsWith('http')) {
                imageSrc = image.image_url;
              }
            }
            
            return (
              <motion.div
                key={image.id}
                initial={animProps.initial}
                animate={animProps.animate}
                exit={animProps.exit}
                transition={animProps.transition}
                className="absolute inset-0"
              >
                <Image
                  src={imageSrc}
                  alt={`Hero image ${index + 1}`}
                  fill
                  className="object-cover"
                  priority={index === 0}
                  sizes="100vw"
                  loading={index === 0 ? 'eager' : 'lazy'}
                  quality={75}
                  fetchPriority={index === 0 ? 'high' : 'auto'}
                  onError={(e) => {
                    console.error('[Hero] Error loading image:', image.image_url, '->', imageSrc, e);
                  }}
                />
                {/* Матовая вуаль */}
                <div className="absolute inset-0 backdrop-blur-[2px] bg-white/5" />
              </motion.div>
            );
          })}
        </AnimatePresence>
        
        {/* Градиенты поверх изображений */}
        <div className="absolute inset-0 bg-gradient-to-b from-saffron-200/30 via-warm-300/20 to-charcoal-800/40" />
        <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/60 via-transparent to-transparent" />
      </div>

      {/* Content */}
      <div className="relative z-10 container mx-auto px-4 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="max-w-4xl mx-auto"
        >
          {/* Logo */}
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="mb-8"
          >
            <div className="inline-flex items-center justify-center w-32 h-32 mb-3 shadow-2xl rounded-full overflow-hidden bg-saffron-500">
              {siteSettings.logo_url ? (
                <img
                  src={siteSettings.logo_url}
                  alt={siteSettings.site_name}
                  width={128}
                  height={128}
                  className="object-cover rounded-full"
                  style={{ width: '128px', height: '128px' }}
                />
              ) : (
                <span className="text-white text-6xl">EN</span>
              )}
            </div>
          </motion.div>

          {/* Slogan */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.8 }}
            className="text-xl md:text-2xl text-sand-100 mb-10 font-light drop-shadow-md"
          >
            {t('subtitle')}
          </motion.p>

          {/* Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 1 }}
            className="flex flex-col sm:flex-row gap-4 justify-center"
          >
            <Link
              href={`/${locale}/stories`}
              className="px-8 py-4 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-all font-medium text-lg shadow-lg hover:shadow-xl transform hover:scale-105"
            >
              {t('readMore')}
            </Link>
            <a
              href="https://t.me/este_nomada"
              target="_blank"
              rel="noopener noreferrer"
              className="px-8 py-4 bg-transparent border-2 border-white text-white rounded-full hover:bg-white/10 transition-all font-medium text-lg"
            >
              {t('telegramChannel')}
            </a>
          </motion.div>
        </motion.div>
      </div>

      {/* Slide Indicators */}
      {images.length > 1 && (
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex gap-2">
          {images.map((_, index) => (
            <button
              key={index}
              onClick={() => setCurrentIndex(index)}
              className={`w-2 h-2 rounded-full transition-all ${
                index === currentIndex
                  ? 'bg-white w-8'
                  : 'bg-white/50 hover:bg-white/75'
              }`}
              aria-label={`Go to slide ${index + 1}`}
            />
          ))}
        </div>
      )}
    </section>
  );
}
