"use client";

import { useState, useEffect } from "react";
import { useTranslations, useLocale } from 'next-intl';
import { motion } from "framer-motion";
import { getApiUrl } from '@/lib/get-api-url';
import { Package, Clock, CheckCircle, XCircle, User, Mail, Phone, MapPin } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { saveTokens, fetchWithAuth, hasToken, getAccessToken, clearTokens } from '@/lib/auth';

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
  const tReg = useTranslations('registration');
  const locale = useLocale();
  const router = useRouter();
  const [orders, setOrders] = useState<Order[]>([]);
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loginData, setLoginData] = useState({ email: '', password: '' });
  const [loginError, setLoginError] = useState<string | null>(null);
  const [loggingIn, setLoggingIn] = useState(false);
  const [showRegistration, setShowRegistration] = useState(false);
  const [registrationData, setRegistrationData] = useState({
    name: '',
    email: '',
    phone: '',
    password: '',
    passwordConfirm: '',
  });
  const [registrationError, setRegistrationError] = useState<string | null>(null);
  const [registering, setRegistering] = useState(false);
  const [registrationSuccess, setRegistrationSuccess] = useState(false);

  const API_BASE_URL = getApiUrl();

  // Проверяем, есть ли данные заказа в localStorage для предзаполнения
  useEffect(() => {
    const lastOrderData = localStorage.getItem('lastOrderData');
    if (lastOrderData) {
      try {
        const data = JSON.parse(lastOrderData);
        setRegistrationData(prev => ({
          ...prev,
          name: data.name || prev.name,
          email: data.email || prev.email,
          phone: data.phone || prev.phone,
        }));
        // Показываем форму регистрации, если есть данные заказа
        setShowRegistration(true);
        // Удаляем данные из localStorage после использования
        localStorage.removeItem('lastOrderData');
      } catch (e) {
        console.error('Error parsing lastOrderData:', e);
      }
    }
  }, []);

  useEffect(() => {
    // Проверяем наличие токена при загрузке страницы
    // Используем setTimeout, чтобы убедиться, что localStorage доступен
    const checkAuth = () => {
      if (typeof window !== 'undefined') {
        const token = getAccessToken();
        console.log('[Account] useEffect - token exists:', !!token, 'token value:', token ? token.substring(0, 20) + '...' : 'null');
        if (token) {
          loadAccountData();
        } else {
          // Если токена нет, сразу показываем форму входа
          console.log('[Account] No token, showing login form');
          setLoading(false);
          setIsAuthenticated(false);
        }
      }
    };
    
    // Небольшая задержка для гарантии, что localStorage доступен
    const timer = setTimeout(checkAuth, 100);
    
    // Также проверяем при возврате фокуса на окно
    const handleFocus = () => {
      console.log('[Account] Window focused, rechecking auth');
      checkAuth();
    };
    window.addEventListener('focus', handleFocus);
    
    return () => {
      clearTimeout(timer);
      window.removeEventListener('focus', handleFocus);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadAccountData = async () => {
    try {
      setLoading(true);
      
      // Проверяем наличие токена
      const token = getAccessToken();
      console.log('[Account] Loading account data, token exists:', !!token);
      if (!token) {
        console.log('[Account] No token, showing login form');
        setIsAuthenticated(false);
        setCustomer(null);
        setOrders([]);
        setLoading(false);
        return;
      }
      
      // Проверяем, авторизован ли пользователь (используем JWT)
      console.log('[Account] Making request to /customers/ with token');
      const authResponse = await fetchWithAuth(`${API_BASE_URL}/customers/`);
      console.log('[Account] Response status:', authResponse.status);
      
      if (authResponse.ok) {
        const customerData = await authResponse.json();
        console.log('[Account] Customer data received:', { count: customerData?.length || 0 });
        if (customerData && customerData.length > 0) {
          setCustomer(customerData[0]);
          setIsAuthenticated(true);
          console.log('[Account] User authenticated, loading orders');
          
          // Загружаем заказы
          const ordersResponse = await fetchWithAuth(`${API_BASE_URL}/orders/my_orders/`);
          
          if (ordersResponse.ok) {
            const ordersData = await ordersResponse.json();
            setOrders(ordersData);
            console.log('[Account] Orders loaded:', ordersData.length);
          }
        } else {
          // Если данных нет, пользователь не авторизован
          console.log('[Account] No customer data, user not authenticated');
          setIsAuthenticated(false);
          setCustomer(null);
          setOrders([]);
        }
      } else if (authResponse.status === 401) {
        // Если получили 401, токен невалидный или истек
        // НЕ очищаем токены сразу - возможно это временная ошибка
        // Токены уже попытались обновиться в fetchWithAuth
        console.log('[Account] Got 401, but NOT clearing tokens - may be temporary error');
        setIsAuthenticated(false);
        setCustomer(null);
        setOrders([]);
      } else {
        // Другая ошибка
        console.log('[Account] Got error:', authResponse.status);
        setIsAuthenticated(false);
        setCustomer(null);
        setOrders([]);
      }
    } catch (err) {
      console.error("Error loading account data:", err);
      setIsAuthenticated(false);
      setCustomer(null);
      setOrders([]);
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
        const data = await response.json();
        
        // Сохраняем JWT токены
        if (data.access && data.refresh) {
          saveTokens(data.access, data.refresh);
        }
        
        // Если в ответе есть данные клиента, обновляем состояние сразу
        if (data.customer) {
          setCustomer(data.customer);
          setIsAuthenticated(true);
          setLoading(false); // Убираем состояние загрузки
          
          // Загружаем заказы
          const ordersResponse = await fetchWithAuth(`${API_BASE_URL}/orders/my_orders/`);
          if (ordersResponse.ok) {
            const ordersData = await ordersResponse.json();
            setOrders(ordersData);
          }
        } else {
          // Если данных клиента нет в ответе, перезагружаем все данные
          await loadAccountData();
        }
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

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setRegistrationError(null);

    // Валидация
    if (!registrationData.name || !registrationData.email || !registrationData.phone) {
      setRegistrationError(tReg('allFieldsRequired') || t('allFieldsRequired') || 'Все поля обязательны для заполнения');
      return;
    }

    if (!registrationData.password || registrationData.password.length < 8) {
      setRegistrationError(tReg('passwordMinLength') || t('passwordMinLength') || 'Пароль должен содержать минимум 8 символов');
      return;
    }

    if (registrationData.password !== registrationData.passwordConfirm) {
      setRegistrationError(tReg('passwordsDoNotMatch') || t('passwordsDoNotMatch') || 'Пароли не совпадают');
      return;
    }

    setRegistering(true);
    try {
      const response = await fetch(`${API_BASE_URL}/customers/register/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          name: registrationData.name,
          email: registrationData.email,
          phone: registrationData.phone,
          password: registrationData.password,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        
        // Сохраняем JWT токены, если они есть
        if (data.access && data.refresh) {
          saveTokens(data.access, data.refresh);
        }
        
        // Если в ответе есть данные клиента, обновляем состояние сразу
        if (data.customer) {
          setCustomer(data.customer);
          setIsAuthenticated(true);
          setLoading(false); // Убираем состояние загрузки
          setRegistrationSuccess(true);
          
          // Загружаем заказы
          const ordersResponse = await fetchWithAuth(`${API_BASE_URL}/orders/my_orders/`);
          if (ordersResponse.ok) {
            const ordersData = await ordersResponse.json();
            setOrders(ordersData);
          }
        } else {
          setRegistrationSuccess(true);
          setTimeout(() => {
            // Перезагружаем данные аккаунта
            loadAccountData();
          }, 1500);
        }
      } else {
        const errorData = await response.json();
        setRegistrationError(errorData.error || tReg('error') || t('registrationError') || 'Ошибка регистрации');
      }
    } catch (err) {
      console.error("Error registering:", err);
      setRegistrationError(tReg('error') || t('registrationError') || 'Ошибка регистрации');
    } finally {
      setRegistering(false);
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
              
              {/* Переключение между входом и регистрацией */}
              <div className="flex mb-6 bg-sand-100 rounded-lg p-1">
                <button
                  type="button"
                  onClick={() => setShowRegistration(false)}
                  className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
                    !showRegistration
                      ? 'bg-white text-charcoal-900 shadow-sm'
                      : 'text-charcoal-600 hover:text-charcoal-900'
                  }`}
                >
                  {t('login') || 'Вход'}
                </button>
                <button
                  type="button"
                  onClick={() => setShowRegistration(true)}
                  className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors ${
                    showRegistration
                      ? 'bg-white text-charcoal-900 shadow-sm'
                      : 'text-charcoal-600 hover:text-charcoal-900'
                  }`}
                >
                  {t('register') || 'Регистрация'}
                </button>
              </div>

              {registrationSuccess ? (
                <div className="text-center py-8">
                  <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <h3 className="text-xl font-bold text-charcoal-900 mb-2">
                    {tReg('success') || t('registrationSuccess') || 'Регистрация успешна!'}
                  </h3>
                  <p className="text-charcoal-600">
                    {tReg('successMessage') || t('registrationSuccessMessage') || 'Вы успешно зарегистрировались. Теперь вы можете отслеживать свои заказы.'}
                  </p>
                </div>
              ) : showRegistration ? (
                <form onSubmit={handleRegister} className="space-y-4">
                  <p className="text-charcoal-600 mb-6 text-center text-sm">
                    {tReg('subtitle') || t('registrationSubtitle') || 'Создайте аккаунт для отслеживания статуса заказа'}
                  </p>

                  {/* Имя */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {tReg('name') || t('name')} *
                    </label>
                    <input
                      type="text"
                      required
                      value={registrationData.name}
                      onChange={(e) => setRegistrationData({ ...registrationData, name: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={tReg('namePlaceholder') || t('namePlaceholder') || 'Ваше имя'}
                    />
                  </div>

                  {/* Email */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {tReg('email') || t('email')} *
                    </label>
                    <input
                      type="email"
                      required
                      value={registrationData.email}
                      onChange={(e) => setRegistrationData({ ...registrationData, email: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={tReg('emailPlaceholder') || t('emailPlaceholder') || 'your@email.com'}
                    />
                  </div>

                  {/* Телефон */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {tReg('phone') || t('phone')} *
                    </label>
                    <input
                      type="tel"
                      required
                      value={registrationData.phone}
                      onChange={(e) => setRegistrationData({ ...registrationData, phone: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={tReg('phonePlaceholder') || t('phonePlaceholder') || '+34 XXX XXX XXX'}
                    />
                  </div>

                  {/* Пароль */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {tReg('password') || t('password') || 'Пароль'} *
                    </label>
                    <input
                      type="password"
                      required
                      value={registrationData.password}
                      onChange={(e) => setRegistrationData({ ...registrationData, password: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={tReg('passwordPlaceholder') || t('passwordPlaceholder') || 'Минимум 8 символов'}
                    />
                  </div>

                  {/* Подтверждение пароля */}
                  <div>
                    <label className="block text-sm font-medium text-charcoal-700 mb-2">
                      {tReg('passwordConfirm') || t('passwordConfirm') || 'Подтвердите пароль'} *
                    </label>
                    <input
                      type="password"
                      required
                      value={registrationData.passwordConfirm}
                      onChange={(e) => setRegistrationData({ ...registrationData, passwordConfirm: e.target.value })}
                      className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                      placeholder={tReg('passwordConfirmPlaceholder') || t('passwordConfirmPlaceholder') || 'Повторите пароль'}
                    />
                  </div>

                  {registrationError && (
                    <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                      <p className="text-sm text-red-600">{registrationError}</p>
                    </div>
                  )}

                  <button
                    type="submit"
                    disabled={registering}
                    className="w-full px-6 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {registering ? (tReg('registering') || t('registering') || 'Регистрация...') : (tReg('register') || t('register') || 'Зарегистрироваться')}
                  </button>
                </form>
              ) : (
                <>
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

                  {!showRegistration && (
                    <div className="mt-6 text-center">
                      <p className="text-sm text-charcoal-600 mb-2">
                        {t('noAccount') || 'Нет аккаунта?'}
                      </p>
                      <button
                        type="button"
                        onClick={() => setShowRegistration(true)}
                        className="text-saffron-600 hover:text-saffron-700 font-medium"
                      >
                        {tReg('register') || t('register') || 'Зарегистрироваться'}
                      </button>
                    </div>
                  )}
                </>
              )}
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

