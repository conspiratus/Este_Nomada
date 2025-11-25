"use client";

import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useTranslations, useLocale } from 'next-intl';
import { getMenuItems, type MenuItem } from '@/lib/menu-api';
import { Minus, Plus } from 'lucide-react';

interface SelectedDish {
  id: number;
  quantity: number;
}

export default function OrderForm() {
  const t = useTranslations('order');
  const locale = useLocale();
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    selectedDishes: [] as SelectedDish[],
    comment: "",
  });
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    // Загружаем меню из API с учетом локали
    const loadMenuItems = async () => {
      try {
        setLoading(true);
        const items = await getMenuItems(locale as any);
        setMenuItems(items);
      } catch (err) {
        console.error("Error loading menu:", err);
        setMenuItems([]);
      } finally {
        setLoading(false);
      }
    };

    loadMenuItems();
  }, [locale]);

  const handleQuantityChange = (dishId: number, change: number) => {
    setFormData((prev) => {
      const existingIndex = prev.selectedDishes.findIndex((d) => d.id === dishId);
      const dish = menuItems.find((d) => d.id === dishId);
      
      if (!dish) return prev;

      let newQuantity = 0;
      if (existingIndex >= 0) {
        newQuantity = prev.selectedDishes[existingIndex].quantity + change;
      } else {
        newQuantity = change;
      }

      // Не позволяем отрицательное количество
      if (newQuantity < 0) return prev;

      const newSelectedDishes = [...prev.selectedDishes];

      if (newQuantity === 0) {
        // Удаляем блюдо, если количество стало 0
        newSelectedDishes.splice(existingIndex, 1);
      } else if (existingIndex >= 0) {
        // Обновляем количество
        newSelectedDishes[existingIndex] = { id: dishId, quantity: newQuantity };
      } else {
        // Добавляем новое блюдо
        newSelectedDishes.push({ id: dishId, quantity: newQuantity });
      }

      return {
        ...prev,
        selectedDishes: newSelectedDishes,
      };
    });
  };

  const getDishQuantity = (dishId: number): number => {
    const selected = formData.selectedDishes.find((d) => d.id === dishId);
    return selected ? selected.quantity : 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Показываем модальное окно вместо реальной отправки
    setShowModal(true);
  };

  return (
    <>
      <section id="order" className="py-20 bg-white">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
            className="max-w-2xl mx-auto"
          >
            <h2 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-4 text-center">
              {t('title')}
            </h2>
            <p className="text-center text-charcoal-600 mb-8">
              {t('subtitle')}
            </p>

            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Name */}
              <div>
                <label
                  htmlFor="name"
                  className="block text-sm font-medium text-charcoal-700 mb-2"
                >
                  {t('name')} *
                </label>
                <input
                  type="text"
                  id="name"
                  required
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none transition-all"
                  placeholder={t('namePlaceholder')}
                />
              </div>

              {/* Phone */}
              <div>
                <label
                  htmlFor="phone"
                  className="block text-sm font-medium text-charcoal-700 mb-2"
                >
                  {t('phone')} *
                </label>
                <input
                  type="tel"
                  id="phone"
                  required
                  value={formData.phone}
                  onChange={(e) =>
                    setFormData({ ...formData, phone: e.target.value })
                  }
                  className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none transition-all"
                  placeholder={t('phonePlaceholder')}
                />
              </div>

              {/* Dishes Selection */}
              <div>
                <label className="block text-sm font-medium text-charcoal-700 mb-3">
                  {t('dishes')} *
                </label>
                {loading ? (
                  <div className="text-center text-charcoal-500 py-8">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-saffron-500"></div>
                    <p className="mt-2">{t('loading')}</p>
                  </div>
                ) : (
                  <div className="space-y-3 max-h-96 overflow-y-auto p-4 border border-warm-200 rounded-lg bg-sand-50">
                    {menuItems.length > 0 ? (
                      menuItems.map((dish) => {
                        const quantity = getDishQuantity(dish.id);
                        return (
                          <div
                            key={dish.id}
                            className="flex items-center justify-between p-3 bg-white rounded-lg border border-warm-200 hover:border-saffron-300 transition-colors"
                          >
                            <div className="flex-1">
                              <div className="flex items-center justify-between mb-1">
                                <span className="font-medium text-charcoal-900">
                                  {dish.name}
                                </span>
                                {dish.price && (
                                  <span className="text-sm text-saffron-600 font-medium">
                                    {dish.price}€
                                  </span>
                                )}
                              </div>
                              {dish.description && (
                                <div 
                                  className="text-xs text-charcoal-600 line-clamp-1 prose prose-xs max-w-none prose-p:text-charcoal-600 prose-p:my-0"
                                  dangerouslySetInnerHTML={{ __html: dish.description }}
                                />
                              )}
                            </div>
                            
                            {/* Quantity Controls */}
                            <div className="flex items-center space-x-2 ml-4">
                              <button
                                type="button"
                                onClick={() => handleQuantityChange(dish.id, -1)}
                                disabled={quantity === 0}
                                className="p-1.5 rounded-full bg-saffron-100 text-saffron-700 hover:bg-saffron-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                aria-label="Уменьшить количество"
                              >
                                <Minus className="w-4 h-4" />
                              </button>
                              <span className="w-12 text-center font-semibold text-charcoal-900">
                                {quantity}
                              </span>
                              <button
                                type="button"
                                onClick={() => handleQuantityChange(dish.id, 1)}
                                className="p-1.5 rounded-full bg-saffron-100 text-saffron-700 hover:bg-saffron-200 transition-colors"
                                aria-label="Увеличить количество"
                              >
                                <Plus className="w-4 h-4" />
                              </button>
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <div className="text-center text-charcoal-500 py-8">
                        {t('noDishes') || 'Нет доступных блюд'}
                      </div>
                    )}
                  </div>
                )}
                
                {/* Selected Dishes Summary */}
                {formData.selectedDishes.length > 0 && (
                  <div className="mt-4 p-4 bg-saffron-50 rounded-lg border border-saffron-200">
                    <p className="text-sm font-medium text-charcoal-900 mb-2">
                      {t('selectedDishes')}:
                    </p>
                    <div className="space-y-1">
                      {formData.selectedDishes.map((selected) => {
                        const dish = menuItems.find((d) => d.id === selected.id);
                        if (!dish) return null;
                        return (
                          <div
                            key={selected.id}
                            className="flex items-center justify-between text-sm"
                          >
                            <span className="text-charcoal-700">
                              {dish.name} × {selected.quantity}
                            </span>
                            {dish.price && (
                              <span className="text-saffron-700 font-medium">
                                {(dish.price * selected.quantity).toFixed(2)}€
                              </span>
                            )}
                          </div>
                        );
                      })}
                    </div>
                    {formData.selectedDishes.some((s) => {
                      const dish = menuItems.find((d) => d.id === s.id);
                      return dish && dish.price;
                    }) && (
                      <div className="mt-3 pt-3 border-t border-saffron-200 flex items-center justify-between">
                        <span className="font-semibold text-charcoal-900">
                          {t('total')}:
                        </span>
                        <span className="font-bold text-saffron-700 text-lg">
                          {formData.selectedDishes
                            .reduce((total, selected) => {
                              const dish = menuItems.find((d) => d.id === selected.id);
                              return total + (dish?.price || 0) * selected.quantity;
                            }, 0)
                            .toFixed(2)}€
                        </span>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Comment */}
              <div>
                <label
                  htmlFor="comment"
                  className="block text-sm font-medium text-charcoal-700 mb-2"
                >
                  {t('comment')}
                </label>
                <textarea
                  id="comment"
                  rows={4}
                  value={formData.comment}
                  onChange={(e) =>
                    setFormData({ ...formData, comment: e.target.value })
                  }
                  className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none transition-all resize-none"
                  placeholder={t('commentPlaceholder')}
                />
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={formData.selectedDishes.length === 0 || loading}
                className="w-full px-6 py-4 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-all font-medium text-lg disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl transform hover:scale-105"
              >
                {t('submit')}
              </button>
            </form>
          </motion.div>
        </div>
      </section>

      {/* Modal */}
      <AnimatePresence>
        {showModal && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-charcoal-900/50 backdrop-blur-sm z-50"
              onClick={() => setShowModal(false)}
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="fixed inset-0 z-50 flex items-center justify-center p-4"
            >
              <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-8 relative">
                <button
                  onClick={() => setShowModal(false)}
                  className="absolute top-4 right-4 text-charcoal-400 hover:text-charcoal-600 transition-colors"
                  aria-label="Close"
                >
                  <svg
                    className="w-6 h-6"
                    fill="none"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
                <div className="text-center">
                  <div className="w-16 h-16 bg-saffron-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <span className="text-3xl">⏳</span>
                  </div>
                  <h3 className="text-2xl font-bold text-charcoal-900 mb-3">
                    {t('formComingSoon')}
                  </h3>
                  <p className="text-charcoal-600 mb-6">
                    {t('formComingSoonText')}
                  </p>
                  <div className="flex flex-col sm:flex-row gap-3 justify-center">
                    <a
                      href="https://t.me/este_nomada"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="px-6 py-2 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors"
                    >
                      {t('writeTelegram')}
                    </a>
                    <a
                      href="mailto:info@estenomada.es"
                      className="px-6 py-2 border-2 border-saffron-500 text-saffron-600 rounded-full hover:bg-saffron-50 transition-colors"
                    >
                      {t('writeEmail')}
                    </a>
                  </div>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </>
  );
}

