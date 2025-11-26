"use client";

import { motion } from "framer-motion";
import { useLocale } from 'next-intl';
import { useEffect, useState } from 'react';
import Image from 'next/image';

interface CustomSection {
  id: number;
  section_id: string;
  title: string;
  subtitle?: string;
  description: string;
  content?: string;
  image_url?: string;
  order: number;
}

export default function CustomSections() {
  const locale = useLocale();
  const [sections, setSections] = useState<CustomSection[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    const fetchCustomSections = async () => {
      try {
        const response = await fetch(`/api/sections/?section_type=custom&locale=${locale}&published=true`);
        const data = await response.json();
        // Сортируем по order
        const sortedSections = (data.results || []).sort((a: CustomSection, b: CustomSection) => a.order - b.order);
        setSections(sortedSections);
      } catch (error) {
        console.error('[CustomSections] Error fetching custom sections:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchCustomSections();
  }, [locale]);

  if (loading) {
    return null; // Не показываем ничего пока загружается
  }

  if (sections.length === 0) {
    return null; // Не показываем ничего если нет разделов
  }

  return (
    <>
      {sections.map((section, index) => (
        <section 
          key={section.id} 
          id={section.section_id} 
          className={`py-20 ${index % 2 === 0 ? 'bg-white' : 'bg-sand-50'}`}
        >
          <div className="container mx-auto px-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
              {/* Image */}
              {section.image_url && (
                <motion.div
                  initial={{ opacity: 0, x: index % 2 === 0 ? -50 : 50 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8 }}
                  className="relative"
                >
                  <div className="relative aspect-square rounded-lg overflow-hidden shadow-2xl vintage-border">
                    <Image
                      src={section.image_url}
                      alt={section.title}
                      fill
                      className="object-cover"
                      sizes="(max-width: 768px) 100vw, 50vw"
                      quality={75}
                    />
                  </div>
                </motion.div>
              )}

              {/* Text Content */}
              <motion.div
                initial={{ opacity: 0, x: index % 2 === 0 ? 50 : -50 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.8 }}
                className={`space-y-6 ${!section.image_url ? 'md:col-span-2' : ''}`}
              >
                {section.title && (
                  <h2 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-6">
                    {section.title}
                  </h2>
                )}
                {section.subtitle && (
                  <p className="text-xl text-saffron-600 font-medium">
                    {section.subtitle}
                  </p>
                )}
                {section.description && (
                  <div 
                    className="space-y-4 text-charcoal-700 leading-relaxed prose prose-lg max-w-none"
                    dangerouslySetInnerHTML={{ __html: section.description }}
                  />
                )}
                {section.content && (
                  <div 
                    className="text-charcoal-600 prose prose-lg max-w-none"
                    dangerouslySetInnerHTML={{ __html: section.content }}
                  />
                )}
              </motion.div>

              {/* Если нет изображения, показываем только текст по центру */}
              {!section.image_url && (
                <motion.div
                  initial={{ opacity: 0 }}
                  whileInView={{ opacity: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.8 }}
                  className="md:col-span-2"
                />
              )}
            </div>
          </div>
        </section>
      ))}
    </>
  );
}

