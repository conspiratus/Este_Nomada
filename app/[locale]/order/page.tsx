"use client";

import { useState, useEffect } from "react";
import { useTranslations, useLocale } from 'next-intl';
import { motion } from "framer-motion";
import { getMenuItems, type MenuItem } from '@/lib/menu-api';
import { getApiUrl } from '@/lib/get-api-url';
import { Plus, Minus, Heart, ShoppingCart, MapPin, X } from 'lucide-react';
import Image from 'next/image';
import type { MenuCategoryGroup } from '@/lib/menu-api';
import RegistrationModal from '@/components/modals/RegistrationModal';
import { useRouter } from 'next/navigation';
import { fetchWithAuth, getAccessToken } from '@/lib/auth';

interface CartItem {
  id: number;
  menu_item: MenuItem;
  quantity: number;
  subtotal: number;
}

interface DeliveryCalculation {
  success: boolean;
  distance?: number;
  cost?: number;
  free_delivery?: boolean;
  address?: string;
  error?: string;
}

export default function OrderPage() {
  const t = useTranslations('order');
  const locale = useLocale();
  const router = useRouter();
  const [cart, setCart] = useState<CartItem[]>([]);
  const [menuCategories, setMenuCategories] = useState<MenuCategoryGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedItem, setSelectedItem] = useState<MenuItem | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    postal_code: "",
    address: "",
    comment: "",
    is_pickup: false,
  });
  const [deliveryInfo, setDeliveryInfo] = useState<DeliveryCalculation | null>(null);
  const [calculatingDelivery, setCalculatingDelivery] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [showRegistrationModal, setShowRegistrationModal] = useState(false);
  const [lastOrderData, setLastOrderData] = useState<{
    name: string;
    email: string;
    phone: string;
  } | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  const API_BASE_URL = getApiUrl();

  useEffect(() => {
    loadMenuItems();
    loadCart();
    loadCustomerData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [locale]);

  const loadMenuItems = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE_URL}/menu/by_category/?locale=${locale}`, {
        credentials: 'include',
      });
      if (response.ok) {
        const data = await response.json();
        setMenuCategories(data);
      } else {
        console.error("Error loading menu:", response.status);
        setMenuCategories([]);
      }
    } catch (err) {
      console.error("Error loading menu:", err);
      setMenuCategories([]);
    } finally {
      setLoading(false);
    }
  };

  const loadCart = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/cart/?locale=${locale}`, {
        credentials: 'include',
      });
      if (response.ok) {
        const data = await response.json();
        // API возвращает объект с полем items
        if (data && data.items) {
          setCart(data.items);
        } else if (Array.isArray(data)) {
          // Если API возвращает массив напрямую
          setCart(data);
        } else {
          setCart([]);
        }
      } else {
        setCart([]);
      }
    } catch (err) {
      console.error("Error loading cart:", err);
      setCart([]);
    }
  };

  const loadCustomerData = async () => {
    try {
      // Проверяем наличие токена
      const token = getAccessToken();
      if (!token) {
        console.log('[Order] No token, skipping customer data load');
        return;
      }

      console.log('[Order] Loading customer data');
      const response = await fetchWithAuth(`${API_BASE_URL}/customers/`);
      
      if (response.ok) {
        const customerData = await response.json();
        console.log('[Order] Customer data received:', { count: customerData?.length || 0 });
        
        if (customerData && customerData.length > 0) {
          const customer = customerData[0];
          console.log('[Order] Filling form with customer data:', {
            name: customer.name,
            email: customer.email_display,
            phone: customer.phone_display,
            postal_code: customer.postal_code,
            address: customer.address
          });
          
          // Заполняем форму данными пользователя
          // Используем email_readable и phone_readable, если доступны, иначе используем display версии
          setFormData(prev => ({
            ...prev,
            name: customer.name || prev.name,
            email: customer.email_readable || customer.email_display || prev.email,
            phone: customer.phone_readable || customer.phone_display || prev.phone,
            postal_code: customer.postal_code || prev.postal_code,
            address: customer.address || prev.address,
          }));
          
          // Пользователь авторизован - блокируем поля имени и email
          setIsAuthenticated(true);
        } else {
          setIsAuthenticated(false);
        }
      } else {
        console.log('[Order] Failed to load customer data:', response.status);
        setIsAuthenticated(false);
      }
    } catch (err) {
      console.error("[Order] Error loading customer data:", err);
      setIsAuthenticated(false);
    }
  };

  const addToCart = async (menuItemId: number, quantity: number = 1) => {
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
          quantity: quantity,
        }),
      });

      if (response.ok) {
        await loadCart();
      }
    } catch (err) {
      console.error("Error adding to cart:", err);
    }
  };

  const updateCartItem = async (cartItemId: number, quantity: number) => {
    try {
      // Проверяем остаток на фронте перед обновлением корзины
      const cartItem = cart.find(ci => ci.id === cartItemId);
      if (cartItem && cartItem.menu_item.stock_quantity !== null && cartItem.menu_item.stock_quantity !== undefined) {
        if (quantity > cartItem.menu_item.stock_quantity) {
          alert(t('insufficientStock') || `Недостаточно остатка. Доступно: ${cartItem.menu_item.stock_quantity}`);
          return;
        }
      }
      
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
        await loadCart();
      } else {
        // Если бэкенд вернул ошибку (например, недостаточно остатка)
        const errorData = await response.json().catch(() => ({}));
        alert(errorData.error || t('errorUpdatingCart') || 'Ошибка при обновлении корзины');
      }
    } catch (err) {
      console.error("Error updating cart:", err);
      alert(t('errorUpdatingCart') || 'Ошибка при обновлении корзины');
    }
  };

  const removeFromCart = async (cartItemId: number) => {
    try {
      let cartResponse = await fetch(`${API_BASE_URL}/cart/?locale=${locale}`, {
        credentials: 'include',
      });
      let cartData = await cartResponse.json();
      const cartId = cartData.id;

      const response = await fetch(`${API_BASE_URL}/cart/${cartId}/remove_item/?cart_item_id=${cartItemId}`, {
        method: 'DELETE',
        credentials: 'include',
      });

      if (response.ok) {
        await loadCart();
      }
    } catch (err) {
      console.error("Error removing from cart:", err);
    }
  };

  const calculateDelivery = async () => {
    // Не рассчитываем доставку при самовывозе
    if (formData.is_pickup || !formData.postal_code) {
      return;
    }

    setCalculatingDelivery(true);
    try {
      const orderTotal = cart.reduce((sum, item) => sum + item.subtotal, 0);
      const response = await fetch(`${API_BASE_URL}/delivery/calculate/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          postal_code: formData.postal_code,
          order_total: orderTotal,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setDeliveryInfo(data);
        if (data.address) {
          setFormData(prev => ({ ...prev, address: data.address }));
        }
      } else {
        const error = await response.json();
        setDeliveryInfo({
          success: false,
          error: error.error || t('deliveryError'),
        });
      }
    } catch (err) {
      console.error("Error calculating delivery:", err);
      setDeliveryInfo({
        success: false,
        error: t('deliveryCalculationError'),
      });
    } finally {
      setCalculatingDelivery(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Валидация обязательных полей
    if (!formData.name) {
      alert(t('nameRequired') || 'Имя обязательно для заполнения');
      return;
    }
    
    if (!formData.email || !formData.phone) {
      alert(t('emailRequired'));
      return;
    }

    if (cart.length === 0) {
      alert(t('cartEmpty'));
      return;
    }

    // Валидация для доставки (если не самовывоз)
    if (!formData.is_pickup && !formData.postal_code) {
      alert(t('postalCodeRequired') || 'Почтовый индекс обязателен для доставки');
      return;
    }

    setSubmitting(true);
    try {
      const selectedDishes = cart.map(item => ({
        menu_item_id: item.menu_item.id,
        quantity: item.quantity,
      }));

      const orderData = {
        name: formData.name,
        email: formData.email,
        phone: formData.phone,
        is_pickup: formData.is_pickup,
        postal_code: formData.is_pickup ? '' : formData.postal_code,
        address: formData.is_pickup ? '' : (deliveryInfo?.address || formData.address),
        comment: formData.comment,
        delivery_cost: formData.is_pickup ? 0 : (deliveryInfo?.cost || 0),
        delivery_distance: formData.is_pickup ? null : (deliveryInfo?.distance || null),
        selected_dishes: selectedDishes,
      };

      // Используем fetchWithAuth для передачи токена авторизации
      const response = await fetchWithAuth(`${API_BASE_URL}/orders/`, {
        method: 'POST',
        body: JSON.stringify(orderData),
      });

      if (response.ok) {
        const orderResponse = await response.json();
        setShowSuccess(true);
        
        // Сохраняем данные заказа в localStorage для предзаполнения формы регистрации
        const orderData = {
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
        };
        localStorage.setItem('lastOrderData', JSON.stringify(orderData));
        
        // Проверяем, зарегистрирован ли пользователь
        // Если нет - редиректим на страницу аккаунта, где можно зарегистрироваться
        setTimeout(() => {
          // Проверяем, есть ли у пользователя аккаунт
          fetch(`${API_BASE_URL}/customers/`, {
            credentials: 'include',
          }).then(res => {
            if (res.ok) {
              res.json().then(customers => {
                const customer = customers && customers.length > 0 ? customers[0] : null;
                if (!customer || !customer.is_registered) {
                  // Пользователь не зарегистрирован - редиректим на страницу аккаунта
                  router.push(`/${locale}/account`);
                }
              });
            } else {
              // Пользователь не авторизован - редиректим на страницу аккаунта
              router.push(`/${locale}/account`);
            }
          }).catch(() => {
            // В случае ошибки редиректим на страницу аккаунта
            router.push(`/${locale}/account`);
          });
        }, 2000);
        
        // Очищаем корзину и форму
        setCart([]);
        setFormData({
          name: "",
          email: "",
          phone: "",
          postal_code: "",
          address: "",
          comment: "",
          is_pickup: false,
        });
        setDeliveryInfo(null);
      } else {
        const error = await response.json();
        alert(error.error || t('orderError'));
      }
    } catch (err) {
      console.error("Error submitting order:", err);
      alert(t('orderError'));
    } finally {
      setSubmitting(false);
    }
  };

  const cartTotal = cart.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryCost = formData.is_pickup ? 0 : (deliveryInfo?.cost || 0);
  const orderTotal = cartTotal + deliveryCost;

  return (
    <div className="min-h-screen bg-sand-50 py-20">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="max-w-6xl mx-auto"
        >
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-8 text-center">
            {t('title')}
          </h1>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Левая колонка - Меню */}
            <div className="lg:col-span-2">
              <div className="bg-white rounded-2xl shadow-lg p-6 mb-6">
                <h2 className="text-2xl font-bold text-charcoal-900 mb-4">
                  {t('dishes')}
                </h2>
                {loading ? (
                  <div className="text-center py-8">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-saffron-500"></div>
                    <p className="mt-2 text-charcoal-600">{t('loading')}</p>
                  </div>
                ) : (
                  <div className="space-y-8">
                    {menuCategories.map((category) => (
                      <div key={category.id || 'no-category'}>
                        <h3 className="text-xl font-bold text-charcoal-900 mb-4 pb-2 border-b border-warm-200">
                          {category.name}
                        </h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          {category.items.map((item) => {
                            const cartItem = cart.find(ci => ci.menu_item.id === item.id);
                            const quantity = cartItem?.quantity || 0;
                            
                            // Проверяем, закончилось ли блюдо
                            const isOutOfStock = item.stock_quantity !== null && item.stock_quantity === 0;
                            
                            // Получаем изображение: первое из images или из image поля
                            const itemImage = item.images && item.images.length > 0 
                              ? item.images[0].image_url 
                              : item.image;
                            
                            return (
                              <motion.div
                                key={item.id}
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ duration: 0.3 }}
                                className={`bg-white border border-warm-200 rounded-lg overflow-hidden transition-all relative ${
                                  isOutOfStock ? 'cursor-not-allowed' : 'hover:shadow-lg cursor-pointer'
                                }`}
                                onClick={() => !isOutOfStock && setSelectedItem(item)}
                              >
                                {/* Overlay для закончившихся блюд */}
                                {isOutOfStock && (
                                  <div className="absolute inset-0 bg-gray-500 bg-opacity-75 z-10 flex items-center justify-center rounded-lg">
                                    <span className="text-white font-semibold text-lg px-4 py-2 bg-gray-800 bg-opacity-90 rounded-lg">
                                      {t('outOfStock') || 'Нет в наличии'}
                                    </span>
                                  </div>
                                )}
                                
                                <div className={`relative h-48 bg-sand-100 ${isOutOfStock ? 'opacity-50' : ''}`}>
                                  {itemImage ? (
                                    <Image
                                      src={itemImage}
                                      alt={item.name}
                                      fill
                                      className="object-cover"
                                      sizes="(max-width: 768px) 100vw, 50vw"
                                    />
                                  ) : (
                                    <div className="w-full h-full flex items-center justify-center text-charcoal-400">
                                      <ShoppingCart className="w-16 h-16" />
                                    </div>
                                  )}
                                </div>
                                <div className={`p-4 ${isOutOfStock ? 'opacity-50' : ''}`}>
                                  <div className="flex items-start justify-between mb-2">
                                    <h4 className="font-semibold text-charcoal-900">
                                      {item.name}
                                    </h4>
                                    {!isOutOfStock && item.low_stock && item.stock_quantity !== null && (
                                      <span className="ml-2 px-2 py-1 text-xs font-semibold bg-orange-100 text-orange-800 rounded-full whitespace-nowrap">
                                        {t('lowStock') || 'Осталось'} {item.stock_quantity}
                                      </span>
                                    )}
                                  </div>
                                  {item.description && (
                                    <div
                                      className="text-sm text-charcoal-600 line-clamp-2 mb-3 prose prose-sm max-w-none"
                                      dangerouslySetInnerHTML={{ __html: item.description }}
                                    />
                                  )}
                                  <div className="flex items-center justify-between">
                                    {item.price && (
                                      <p className="text-saffron-600 font-bold text-lg">
                                        {item.price}€
                                      </p>
                                    )}
                                    {!isOutOfStock && (
                                      <div className="flex items-center space-x-2">
                                        {quantity > 0 && (
                                          <button
                                            onClick={(e) => {
                                              e.stopPropagation();
                                              updateCartItem(cartItem!.id, quantity - 1);
                                            }}
                                            className="p-1.5 rounded-full bg-saffron-100 text-saffron-700 hover:bg-saffron-200 transition-colors"
                                            aria-label={t('decreaseQuantity')}
                                          >
                                            <Minus className="w-4 h-4" />
                                          </button>
                                        )}
                                        {quantity > 0 && (
                                          <span className="w-8 text-center font-semibold text-charcoal-900">
                                            {quantity}
                                          </span>
                                        )}
                                        <button
                                          onClick={(e) => {
                                            e.stopPropagation();
                                            addToCart(item.id, 1);
                                          }}
                                          className="p-1.5 rounded-full bg-saffron-500 text-white hover:bg-saffron-600 transition-colors"
                                          aria-label={t('addToCart')}
                                        >
                                          <Plus className="w-4 h-4" />
                                        </button>
                                      </div>
                                    )}
                                  </div>
                                </div>
                              </motion.div>
                            );
                          })}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Правая колонка - Корзина и форма */}
            <div className="lg:col-span-1">
              {/* Корзина */}
              <div className="bg-white rounded-2xl shadow-lg p-6 mb-6">
                <h2 className="text-2xl font-bold text-charcoal-900 mb-4 flex items-center">
                  <ShoppingCart className="w-6 h-6 mr-2" />
                  {t('cart')}
                </h2>
                {cart.length === 0 ? (
                  <p className="text-charcoal-600 text-center py-8">
                    {t('emptyCart')}
                  </p>
                ) : (
                  <>
                    <div className="space-y-3 mb-4">
                      {cart.map((item) => (
                        <div
                          key={item.id}
                          className="flex items-center justify-between p-3 bg-sand-50 rounded-lg"
                        >
                          <div className="flex-1">
                            <p className="font-medium text-charcoal-900 text-sm">
                              {item.menu_item.name}
                            </p>
                            <p className="text-xs text-charcoal-600">
                              {item.quantity} × {item.menu_item.price}€ = {item.subtotal.toFixed(2)}€
                            </p>
                          </div>
                          <button
                            onClick={() => removeFromCart(item.id)}
                            className="ml-2 text-red-500 hover:text-red-700"
                            aria-label={t('removeFromCart')}
                          >
                            <Minus className="w-4 h-4" />
                          </button>
                        </div>
                      ))}
                    </div>
                    <div className="border-t border-warm-200 pt-4">
                      <div className="flex justify-between mb-2">
                        <span className="text-charcoal-700">{t('items')}:</span>
                        <span className="font-semibold">{cartTotal.toFixed(2)}€</span>
                      </div>
                      {!formData.is_pickup && (
                        <div className="flex justify-between mb-2">
                          <span className="text-charcoal-700">{t('delivery')}:</span>
                          <span className="font-semibold">
                            {deliveryInfo?.free_delivery ? t('free') : `${deliveryCost.toFixed(2)}€`}
                          </span>
                        </div>
                      )}
                      {formData.is_pickup && (
                        <div className="flex justify-between mb-2">
                          <span className="text-charcoal-700">{t('delivery')}:</span>
                          <span className="font-semibold">{t('free')}</span>
                        </div>
                      )}
                      <div className="flex justify-between text-lg font-bold text-charcoal-900 pt-2 border-t border-warm-200">
                        <span>{t('total')}:</span>
                        <span className="text-saffron-600">{orderTotal.toFixed(2)}€</span>
                      </div>
                    </div>
                  </>
                )}
              </div>

              {/* Форма заказа */}
              <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-lg p-6">
                <h2 className="text-2xl font-bold text-charcoal-900 mb-4">
                  {t('orderData')}
                </h2>

                <div className="space-y-4">
                  {/* Имя */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {t('name')} *
                    </label>
                    <input
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      readOnly={isAuthenticated}
                      disabled={isAuthenticated}
                      className={`w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none ${
                        isAuthenticated ? 'bg-gray-100 cursor-not-allowed opacity-75' : ''
                      }`}
                      placeholder={t('namePlaceholder')}
                    />
                  </div>

                  {/* Email */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {t('email')} *
                    </label>
                    <input
                      type="email"
                      required
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      readOnly={isAuthenticated}
                      disabled={isAuthenticated}
                      className={`w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none ${
                        isAuthenticated ? 'bg-gray-100 cursor-not-allowed opacity-75' : ''
                      }`}
                      placeholder={t('emailPlaceholder')}
                    />
                  </div>

                  {/* Телефон */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {t('phone')} *
                    </label>
                    <input
                      type="tel"
                      required
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={t('phonePlaceholder')}
                    />
                  </div>

                  {/* Самовывоз */}
                  <div>
                    <label className="flex items-center cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formData.is_pickup}
                        onChange={(e) => {
                          setFormData({ ...formData, is_pickup: e.target.checked, postal_code: '', address: '' });
                          setDeliveryInfo(null);
                        }}
                        className="w-5 h-5 text-saffron-600 border-warm-300 rounded focus:ring-saffron-500"
                      />
                      <span className="ml-2 text-sm font-medium text-charcoal-700">
                        {t('pickup')}
                      </span>
                    </label>
                  </div>

                  {/* Почтовый индекс (скрыт при самовывозе) */}
                  {!formData.is_pickup && (
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                      <MapPin className="w-4 h-4 mr-1" />
                      {t('postalCode')} *
                    </label>
                    <div className="flex space-x-2">
                      <input
                        type="text"
                        value={formData.postal_code}
                        onChange={(e) => setFormData({ ...formData, postal_code: e.target.value })}
                        onBlur={calculateDelivery}
                        className="flex-1 px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                        placeholder={t('postalCodePlaceholder')}
                      />
                      <button
                        type="button"
                        onClick={calculateDelivery}
                        disabled={calculatingDelivery || !formData.postal_code}
                        className="px-4 py-3 bg-saffron-500 text-white rounded-lg hover:bg-saffron-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                      >
                        {calculatingDelivery ? t('calculatingDelivery') : t('calculateDelivery')}
                      </button>
                    </div>
                    {deliveryInfo && (
                      <div className="mt-2 text-sm">
                        {deliveryInfo.success ? (
                          <div className="text-green-600">
                            <p>{t('deliveryCost')}: {deliveryInfo.free_delivery ? t('free') : `${deliveryInfo.cost}€`}</p>
                            {deliveryInfo.address && (
                              <p className="text-charcoal-600 text-xs mt-1">{deliveryInfo.address}</p>
                            )}
                          </div>
                        ) : (
                          <p className="text-red-600">{deliveryInfo.error}</p>
                        )}
                      </div>
                    )}
                  </div>
                  )}

                  {/* Адрес (скрыт при самовывозе) */}
                  {!formData.is_pickup && (
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {t('address')}
                    </label>
                    <textarea
                      value={formData.address}
                      onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                      rows={3}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none resize-none"
                      placeholder={t('addressPlaceholder')}
                    />
                  </div>
                  )}

                  {/* Комментарий */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {t('comment')}
                    </label>
                    <textarea
                      value={formData.comment}
                      onChange={(e) => setFormData({ ...formData, comment: e.target.value })}
                      rows={3}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none resize-none"
                      placeholder={t('commentPlaceholder')}
                    />
                  </div>

                  {/* Кнопка отправки */}
                  <button
                    type="submit"
                    disabled={submitting || cart.length === 0}
                    className="w-full px-6 py-4 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-all font-medium text-lg disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
                  >
                    {submitting ? t('submitting') : t('submit')}
                  </button>

                  {showSuccess && (
                    <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
                      <p className="font-semibold">{t('success')}</p>
                      <p className="text-sm mt-1">{t('successMessage')}</p>
                    </div>
                  )}
                </div>
              </form>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Модальное окно для описания блюда */}
      {selectedItem && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
          onClick={() => setSelectedItem(null)}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="relative h-64 bg-sand-100">
              {(() => {
                const itemImage = selectedItem.images && selectedItem.images.length > 0 
                  ? selectedItem.images[0].image_url 
                  : selectedItem.image;
                return itemImage ? (
                  <Image
                    src={itemImage}
                    alt={selectedItem.name}
                    fill
                    className="object-cover rounded-t-2xl"
                    sizes="(max-width: 768px) 100vw, 768px"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-charcoal-400">
                    <ShoppingCart className="w-24 h-24" />
                  </div>
                );
              })()}
              <button
                onClick={() => setSelectedItem(null)}
                className="absolute top-4 right-4 p-2 bg-white rounded-full shadow-lg hover:bg-sand-50 transition-colors"
                aria-label={t('close')}
              >
                <X className="w-5 h-5 text-charcoal-900" />
              </button>
            </div>
            <div className="p-6">
              <div className="flex items-start justify-between mb-4">
                <h2 className="text-2xl font-bold text-charcoal-900">
                  {selectedItem.name}
                </h2>
                {selectedItem.low_stock && selectedItem.stock_quantity !== null && (
                  <span className="ml-4 px-3 py-1 text-sm font-semibold bg-orange-100 text-orange-800 rounded-full whitespace-nowrap">
                    {t('lowStock') || 'Осталось'} {selectedItem.stock_quantity}
                  </span>
                )}
              </div>
              {selectedItem.description && (
                <div
                  className="text-charcoal-700 mb-6 prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: selectedItem.description }}
                />
              )}
              {selectedItem.price && (
                <p className="text-2xl font-bold text-saffron-600 mb-6">
                  {selectedItem.price}€
                </p>
              )}
              <div className="flex items-center justify-end space-x-3">
                {(() => {
                  const cartItem = cart.find(ci => ci.menu_item.id === selectedItem.id);
                  const quantity = cartItem?.quantity || 0;
                  
                  return (
                    <>
                      {quantity > 0 && (
                        <button
                          onClick={() => updateCartItem(cartItem!.id, quantity - 1)}
                          className="p-2 rounded-full bg-saffron-100 text-saffron-700 hover:bg-saffron-200 transition-colors"
                          aria-label={t('decreaseQuantity')}
                        >
                          <Minus className="w-5 h-5" />
                        </button>
                      )}
                      {quantity > 0 && (
                        <span className="w-12 text-center font-semibold text-charcoal-900 text-lg">
                          {quantity}
                        </span>
                      )}
                      <button
                        onClick={() => {
                          addToCart(selectedItem.id, 1);
                        }}
                        className="px-6 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium"
                        aria-label={t('addToCart')}
                      >
                        <Plus className="w-5 h-5 inline mr-2" />
                        {t('addToCart')}
                      </button>
                    </>
                  );
                })()}
              </div>
            </div>
          </motion.div>
        </div>
      )}

      {/* Модальное окно регистрации */}
      <RegistrationModal
        isOpen={showRegistrationModal}
        onClose={() => setShowRegistrationModal(false)}
        onSuccess={() => {
          setShowRegistrationModal(false);
        }}
        initialData={lastOrderData || undefined}
      />
    </div>
  );
}

