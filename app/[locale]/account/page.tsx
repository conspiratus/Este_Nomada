"use client";

import { useState, useEffect } from "react";
import { useTranslations, useLocale } from 'next-intl';
import { motion } from "framer-motion";
import { getApiUrl } from '@/lib/get-api-url';
import { Package, Clock, CheckCircle, XCircle, User, Mail, Phone, MapPin } from 'lucide-react';
import { useRouter } from 'next/navigation';

interface OrderItem {
  id: number;
  menu_item: {
    id: number;
    name: string;
    price: string;
  };
  quantity: number;
}

interface Order {
  id: number;
  name: string;
  email_display: string;
  phone_display: string;
  is_pickup: boolean;
  postal_code: string | null;
  address: string | null;
  delivery_cost: string;
  delivery_distance: string | null;
  comment: string | null;
  status: 'pending' | 'processing' | 'completed' | 'cancelled';
  order_items: OrderItem[];
  total: string;
  created_at: string;
  updated_at: string;
}

interface Customer {
  id: number;
  name: string;
  email_display: string;
  phone_display: string;
  postal_code: string | null;
  address: string | null;
  is_registered: boolean;
  email_verified: boolean;
}

export default function AccountPage() {
  const t = useTranslations('account');
  const locale = useLocale();
  const router = useRouter();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loginData, setLoginData] = useState({ email: '', password: '' });
  const [loginError, setLoginError] = useState<string | null>(null);
  const [loggingIn, setLoggingIn] = useState(false);

  const API_BASE_URL = getApiUrl();

  useEffect(() => {
    loadAccountData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadAccountData = async () => {
    try {
      setLoading(true);
      
      // Проверяем, авторизован ли пользователь
      const authResponse = await fetch(`${API_BASE_URL}/customers/`, {
        credentials: 'include',
      });
      
      if (authResponse.ok) {
        const customerData = await authResponse.json();
        if (customerData && customerData.length > 0) {
          setCustomer(customerData[0]);
          setIsAuthenticated(true);
          
          // Загружаем заказы
          const ordersResponse = await fetch(`${API_BASE_URL}/orders/my_orders/?locale=${locale}`, {
            credentials: 'include',
          });
          
          if (ordersResponse.ok) {
            const ordersData = await ordersResponse.json();
            setOrders(ordersData);
          }
        }
      }
    } catch (err) {
      console.error("Error loading account data:", err);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-green-600" />;
      case 'cancelled':
        return <XCircle className="w-5 h-5 text-red-600" />;
      case 'processing':
        return <Clock className="w-5 h-5 text-blue-600" />;
      default:
        return <Package className="w-5 h-5 text-yellow-600" />;
    }
  };

  const getStatusText = (status: string) => {
    return t(`status.${status}`) || status;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'processing':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-yellow-100 text-yellow-800';
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString(locale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError(null);
    setLoggingIn(true);

    try {
      const response = await fetch(`${API_BASE_URL}/customers/login/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify(loginData),
      });

      if (response.ok) {
        // Перезагружаем данные аккаунта
        await loadAccountData();
      } else {
        const errorData = await response.json();
        setLoginError(errorData.error || t('loginError') || 'Ошибка входа');
      }
    } catch (err) {
      console.error("Error logging in:", err);
      setLoginError(t('loginError') || 'Ошибка входа');
    } finally {
      setLoggingIn(false);
    }
  };

  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-sand-50 py-20">
        <div className="container mx-auto px-4">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8 }}
            className="max-w-md mx-auto"
          >
            <div className="bg-white rounded-2xl shadow-lg p-8">
              <h1 className="text-3xl font-bold text-charcoal-900 mb-2 text-center">
                {t('title')}
              </h1>
              <p className="text-charcoal-600 mb-6 text-center">
                {t('loginMessage') || 'Войдите в свой аккаунт'}
              </p>

              <form onSubmit={handleLogin} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2">
                    {t('email')}
                  </label>
                  <input
                    type="email"
                    required
                    value={loginData.email}
                    onChange={(e) => setLoginData({ ...loginData, email: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('emailPlaceholder') || 'your@email.com'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2">
                    {t('password') || 'Пароль'}
                  </label>
                  <input
                    type="password"
                    required
                    value={loginData.password}
                    onChange={(e) => setLoginData({ ...loginData, password: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('passwordPlaceholder') || 'Введите пароль'}
                  />
                </div>

                {loginError && (
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                    <p className="text-sm text-red-600">{loginError}</p>
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loggingIn}
                  className="w-full px-6 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loggingIn ? (t('loggingIn') || 'Вход...') : (t('login') || 'Войти')}
                </button>
              </form>

              <div className="mt-6 text-center">
                <p className="text-sm text-charcoal-600 mb-2">
                  {t('noAccount') || 'Нет аккаунта?'}
                </p>
                <button
                  onClick={() => router.push(`/${locale}/order`)}
                  className="text-saffron-600 hover:text-saffron-700 font-medium"
                >
                  {t('goToOrder')}
                </button>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-sand-50 py-20">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="max-w-6xl mx-auto"
        >
          <h1 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-8">
            {t('title')}
          </h1>

          {/* Предупреждение о неподтвержденном email */}
          {customer && !customer.email_verified && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6"
            >
              <div className="flex items-start">
                <div className="flex-shrink-0">
                  <svg className="w-5 h-5 text-yellow-600" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-yellow-800">
                    {t('emailNotVerified') || 'Email не подтвержден'}
                  </h3>
                  <p className="mt-1 text-sm text-yellow-700">
                    {t('emailNotVerifiedMessage') || 'Пожалуйста, подтвердите ваш email адрес. Проверьте почту и перейдите по ссылке из письма.'}
                  </p>
                </div>
              </div>
            </motion.div>
          )}

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Информация о пользователе */}
            <div className="lg:col-span-1">
              <div className="bg-white rounded-2xl shadow-lg p-6 mb-6">
                <h2 className="text-2xl font-bold text-charcoal-900 mb-4 flex items-center">
                  <User className="w-6 h-6 mr-2" />
                  {t('profile')}
                </h2>
                {customer && (
                  <div className="space-y-4">
                    <div>
                      <p className="text-sm text-charcoal-600">{t('name')}</p>
                      <p className="font-semibold text-charcoal-900">{customer.name || '-'}</p>
                    </div>
                    <div>
                      <p className="text-sm text-charcoal-600 flex items-center">
                        <Mail className="w-4 h-4 mr-1" />
                        {t('email')}
                      </p>
                      <p className="font-semibold text-charcoal-900">{customer.email_display || '-'}</p>
                    </div>
                    <div>
                      <p className="text-sm text-charcoal-600 flex items-center">
                        <Phone className="w-4 h-4 mr-1" />
                        {t('phone')}
                      </p>
                      <p className="font-semibold text-charcoal-900">{customer.phone_display || '-'}</p>
                    </div>
                    {customer.postal_code && (
                      <div>
                        <p className="text-sm text-charcoal-600 flex items-center">
                          <MapPin className="w-4 h-4 mr-1" />
                          {t('postalCode')}
                        </p>
                        <p className="font-semibold text-charcoal-900">{customer.postal_code}</p>
                      </div>
                    )}
                    {customer.address && (
                      <div>
                        <p className="text-sm text-charcoal-600">{t('address')}</p>
                        <p className="font-semibold text-charcoal-900">{customer.address}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Заказы */}
            <div className="lg:col-span-2">
              <div className="bg-white rounded-2xl shadow-lg p-6">
                <h2 className="text-2xl font-bold text-charcoal-900 mb-6 flex items-center">
                  <Package className="w-6 h-6 mr-2" />
                  {t('orders')}
                </h2>
                
                {orders.length === 0 ? (
                  <div className="text-center py-12">
                    <Package className="w-16 h-16 text-charcoal-300 mx-auto mb-4" />
                    <p className="text-charcoal-600">{t('noOrders')}</p>
                    <button
                      onClick={() => router.push(`/${locale}/order`)}
                      className="mt-4 px-6 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium"
                    >
                      {t('makeOrder')}
                    </button>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {orders.map((order) => (
                      <motion.div
                        key={order.id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="border border-warm-200 rounded-lg p-6 hover:shadow-md transition-shadow"
                      >
                        <div className="flex justify-between items-start mb-4">
                          <div>
                            <h3 className="text-lg font-bold text-charcoal-900">
                              {t('order')} #{order.id}
                            </h3>
                            <p className="text-sm text-charcoal-600 mt-1">
                              {formatDate(order.created_at)}
                            </p>
                          </div>
                          <div className={`flex items-center space-x-2 px-3 py-1 rounded-full ${getStatusColor(order.status)}`}>
                            {getStatusIcon(order.status)}
                            <span className="text-sm font-semibold">
                              {getStatusText(order.status)}
                            </span>
                          </div>
                        </div>

                        <div className="space-y-3">
                          {/* Блюда */}
                          <div>
                            <p className="text-sm font-medium text-charcoal-700 mb-2">{t('items')}:</p>
                            <div className="space-y-2">
                              {order.order_items.map((item) => (
                                <div key={item.id} className="flex justify-between text-sm">
                                  <span className="text-charcoal-700">
                                    {item.menu_item.name} × {item.quantity}
                                  </span>
                                  <span className="font-semibold">
                                    {(parseFloat(item.menu_item.price) * item.quantity).toFixed(2)}€
                                  </span>
                                </div>
                              ))}
                            </div>
                          </div>

                          {/* Детали заказа */}
                          <div className="border-t border-warm-200 pt-3 space-y-2">
                            {!order.is_pickup && order.delivery_cost && (
                              <div className="flex justify-between text-sm">
                                <span className="text-charcoal-600">{t('delivery')}:</span>
                                <span className="font-semibold">{parseFloat(order.delivery_cost).toFixed(2)}€</span>
                              </div>
                            )}
                            {order.is_pickup && (
                              <div className="flex justify-between text-sm">
                                <span className="text-charcoal-600">{t('delivery')}:</span>
                                <span className="font-semibold">{t('pickup')}</span>
                              </div>
                            )}
                            <div className="flex justify-between text-lg font-bold text-charcoal-900 pt-2 border-t border-warm-200">
                              <span>{t('total')}:</span>
                              <span className="text-saffron-600">{parseFloat(order.total).toFixed(2)}€</span>
                            </div>
                          </div>

                          {order.comment && (
                            <div className="mt-3 pt-3 border-t border-warm-200">
                              <p className="text-sm text-charcoal-600">
                                <span className="font-medium">{t('comment')}:</span> {order.comment}
                              </p>
                            </div>
                          )}
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

