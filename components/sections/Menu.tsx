"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { useTranslations } from 'next-intl';
import Image from "next/image";
import MenuItemModal from '@/components/modals/MenuItemModal';

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

interface MenuProps {
  menuItems: MenuItem[];
}

export default function Menu({ menuItems }: MenuProps) {
  const t = useTranslations('menu');
  const [selectedItem, setSelectedItem] = useState<MenuItem | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleItemClick = (item: MenuItem) => {
    setSelectedItem(item);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedItem(null);
  };

  // Получаем первое изображение для карточки
  const getFirstImage = (item: MenuItem): string | null => {
    if (item.images && item.images.length > 0) {
      return item.images[0].image_url;
    }
    return item.image;
  };

  return (
    <>
      <section id="menu" className="py-20 bg-white">
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

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {menuItems.map((item, index) => {
              const firstImage = getFirstImage(item);
              
              return (
                <motion.div
                  key={item.id}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  onClick={() => handleItemClick(item)}
                  className="bg-sand-50 rounded-lg overflow-hidden shadow-md hover:shadow-xl transition-all transform hover:scale-105 vintage-border cursor-pointer"
                >
                  {/* Image */}
                  <div className="aspect-square bg-gradient-to-br from-saffron-200 to-warm-400 relative overflow-hidden">
                    {firstImage ? (
                      <Image
                        src={firstImage}
                        alt={item.name}
                        fill
                        className="object-cover"
                        sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 25vw"
                        loading="lazy"
                        quality={75}
                      />
                    ) : (
                      <span className="text-6xl">🍲</span>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-charcoal-900/20 to-transparent" />
                  </div>

                  {/* Content */}
                  <div className="p-4">
                    <h3 className="text-xl font-semibold text-charcoal-900 mb-2">
                      {item.name}
                    </h3>
                    {item.description ? (
                      <div 
                        className="text-sm text-charcoal-600 mb-3 line-clamp-2 prose prose-sm max-w-none prose-p:text-charcoal-600 prose-p:my-0"
                        dangerouslySetInnerHTML={{ __html: item.description }}
                      />
                    ) : null}
                    
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-saffron-600 font-medium">
                        {item.category}
                      </span>
                      <span className="text-charcoal-400">
                        {item.price ? `${item.price}€` : "—"}
                      </span>
                    </div>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Modal */}
      <MenuItemModal
        item={selectedItem}
        isOpen={isModalOpen}
        onClose={handleCloseModal}
      />
    </>
  );
}

