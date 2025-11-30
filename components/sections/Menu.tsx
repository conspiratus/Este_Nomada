"use client";

import { useState, useEffect, useCallback } from "react";
import { motion } from "framer-motion";
import { useTranslations, useLocale } from 'next-intl';
import Image from "next/image";
import { ShoppingCart, Plus, Minus } from 'lucide-react';
import MenuItemModal from '@/components/modals/MenuItemModal';
import type { MenuItem } from '@/lib/menu-api';
import { getApiUrl } from '@/lib/get-api-url';

interface MenuProps {
  menuItems: MenuItem[];
}

interface CartItem {
  id: number;
  menu_item: MenuItem;
  quantity: number;
}

export default function Menu({ menuItems }: MenuProps) {
  const t = useTranslations('menu');
  const tOrder = useTranslations('order');
  const locale = useLocale();
  const [selectedItem, setSelectedItem] = useState<MenuItem | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [addingToCart, setAddingToCart] = useState<number | null>(null);
  const [cart, setCart] = useState<CartItem[]>([]);

  const API_BASE_URL = getApiUrl();

  // Загружаем корзину
  const loadCart = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/cart/?locale=${locale}`, {
        credentials: 'include',
      });
      if (response.ok) {
        const cartData = await response.json();
        setCart(cartData.items || []);
      }
    } catch (error) {
      console.error("Error loading cart:", error);
    }
  }, [API_BASE_URL, locale]);

  useEffect(() => {
    loadCart();
    
    // Слушаем обновления корзины
    const handleCartUpdate = () => {
      loadCart();
    };
    window.addEventListener('cartUpdated', handleCartUpdate);
    
    return () => {
      window.removeEventListener('cartUpdated', handleCartUpdate);
    };
  }, [loadCart]);

  const handleItemClick = (item: MenuItem) => {
    setSelectedItem(item);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedItem(null);
  };

  const addToCart = async (menuItemId: number, e: React.MouseEvent) => {
    e.stopPropagation(); // Предотвращаем открытие модального окна
    
    // Проверяем остаток на фронте перед добавлением в корзину
    const menuItem = menuItems.find(item => item.id === menuItemId);
    
    if (menuItem && menuItem.stock_quantity !== null && menuItem.stock_quantity !== undefined) {
      if (menuItem.stock_quantity === 0) {
        alert(tOrder('outOfStock') || 'Нет в наличии');
        return;
      }
    }

    setAddingToCart(menuItemId);
    
    try {
      // Сначала получаем или создаем корзину
      let cartResponse = await fetch(`${API_BASE_URL}/cart/?locale=${locale}`, {
        credentials: 'include',
      });
      let cartData = await cartResponse.json();
      const cartId = cartData.id;

      // Добавляем элемент
      const response = await fetch(`${API_BASE_URL}/cart/${cartId}/add_item/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          menu_item_id: menuItemId,
          quantity: 1,
        }),
      });

      if (response.ok) {
        // Уведомляем Header об обновлении корзины
        window.dispatchEvent(new CustomEvent('cartUpdated'));
        await loadCart();
      } else {
        const errorData = await response.json().catch(() => ({}));
        alert(errorData.error || tOrder('errorAddingToCart') || 'Ошибка при добавлении в корзину');
      }
    } catch (err) {
      console.error("Error adding to cart:", err);
      alert(tOrder('errorAddingToCart') || 'Ошибка при добавлении в корзину');
    } finally {
      setAddingToCart(null);
    }
  };

  const updateCartItem = async (cartItemId: number, quantity: number) => {
    try {
      let cartResponse = await fetch(`${API_BASE_URL}/cart/?locale=${locale}`, {
        credentials: 'include',
      });
      let cartData = await cartResponse.json();
      const cartId = cartData.id;

      const response = await fetch(`${API_BASE_URL}/cart/${cartId}/update_item/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          cart_item_id: cartItemId,
          quantity: quantity,
        }),
      });

      if (response.ok) {
        window.dispatchEvent(new CustomEvent('cartUpdated'));
        await loadCart();
      } else {
        const errorData = await response.json().catch(() => ({}));
        alert(errorData.error || tOrder('errorUpdatingCart') || 'Ошибка при обновлении корзины');
      }
    } catch (err) {
      console.error("Error updating cart:", err);
      alert(tOrder('errorUpdatingCart') || 'Ошибка при обновлении корзины');
    }
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
                    
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-xs text-saffron-600 font-medium">
                        {item.category?.name || '—'}
                      </span>
                      <span className="text-charcoal-400">
                        {item.price ? `${item.price}€` : "—"}
                      </span>
                    </div>
                    
                    {/* Кнопка добавить в корзину или управление количеством */}
                    {item.stock_quantity !== null && item.stock_quantity === 0 ? (
                      <div className="w-full px-4 py-2 bg-gray-300 text-gray-600 rounded-lg text-center text-sm font-medium cursor-not-allowed">
                        {tOrder('outOfStock') || 'Нет в наличии'}
                      </div>
                    ) : (() => {
                      const cartItem = cart.find(ci => ci.menu_item.id === item.id);
                      const quantity = cartItem?.quantity || 0;
                      
                      if (quantity > 0) {
                        // Показываем кнопки +/- если блюдо уже в корзине
                        return (
                          <div className="flex items-center justify-center space-x-2">
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                if (cartItem) {
                                  updateCartItem(cartItem.id, quantity - 1);
                                }
                              }}
                              className="p-1.5 rounded-full bg-saffron-100 text-saffron-700 hover:bg-saffron-200 transition-colors"
                              aria-label={tOrder('decreaseQuantity')}
                            >
                              <Minus className="w-4 h-4" />
                            </button>
                            <span className="w-8 text-center font-semibold text-charcoal-900">
                              {quantity}
                            </span>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                if (cartItem) {
                                  updateCartItem(cartItem.id, quantity + 1);
                                } else {
                                  addToCart(item.id, e);
                                }
                              }}
                              disabled={addingToCart === item.id}
                              className="p-1.5 rounded-full bg-saffron-500 text-white hover:bg-saffron-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                              aria-label={tOrder('addToCart')}
                            >
                              {addingToCart === item.id ? (
                                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                              ) : (
                                <Plus className="w-4 h-4" />
                              )}
                            </button>
                          </div>
                        );
                      } else {
                        // Показываем кнопку "Добавить в корзину" если блюдо не в корзине
                        return (
                          <button
                            onClick={(e) => addToCart(item.id, e)}
                            disabled={addingToCart === item.id}
                            className="w-full px-4 py-2 bg-saffron-500 text-white rounded-lg hover:bg-saffron-600 transition-colors font-medium text-sm flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            {addingToCart === item.id ? (
                              <>
                                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                                <span>{tOrder('adding') || 'Добавление...'}</span>
                              </>
                            ) : (
                              <>
                                <ShoppingCart className="w-4 h-4" />
                                <span>{tOrder('addToCart') || 'В корзину'}</span>
                              </>
                            )}
                          </button>
                        );
                      }
                    })()}
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

