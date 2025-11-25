"use client";

import { motion } from "framer-motion";
import { useTranslations, useLocale } from 'next-intl';
import { useEffect, useState } from 'react';
import Image from 'next/image';

interface AboutSection {
  id: number;
  title: string;
  description: string;
  mission_text: string;
  image_url: string;
  order: number;
}

export default function AboutBrand() {
  const t = useTranslations('about');
  const locale = useLocale();
  const [sections, setSections] = useState<AboutSection[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    const fetchAboutSections = async () => {
      try {
        const response = await fetch(`/api/about/?locale=${locale}`);
        const data = await response.json();
        setSections(data.results || []);
      } catch (error) {
        console.error('[AboutBrand] Error fetching about sections:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchAboutSections();
  }, [locale]);

  // Используем первый раздел или fallback на переводы
  const section = sections[0];
  const title = section?.title || t('title');
  const description = section?.description || t('description');
  const missionText = section?.mission_text || t('missionText');
  const imageUrl = section?.image_url;
  
  return (
    <section id="about" className="py-20 bg-sand-50">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
          {/* Image */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="relative"
          >
            <div className="relative aspect-square rounded-lg overflow-hidden shadow-2xl vintage-border">
              {imageUrl ? (
                <Image
                  src={imageUrl}
                  alt={title}
                  fill
                  className="object-cover"
                  sizes="(max-width: 768px) 100vw, 50vw"
                  quality={75}
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-warm-400 to-charcoal-700 flex items-center justify-center">
                  <span className="text-white text-4xl">🫕</span>
                </div>
              )}
            </div>
          </motion.div>

          {/* Text Content */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="space-y-6"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-6">
              {title}
            </h2>
            <div className="space-y-4 text-charcoal-700 leading-relaxed">
              <p className="text-lg">
                {description}
              </p>
              {missionText && (
                <p className="font-medium text-saffron-600">
                  {missionText}
                </p>
              )}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}

