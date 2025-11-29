"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import Image from "next/image";
import { useTranslations, useLocale } from 'next-intl';
import { usePathname, useRouter } from 'next/navigation';
import { motion, AnimatePresence } from "framer-motion";
import { locales, type Locale } from '@/lib/locales';
import { fetchWithAuth, hasToken } from '@/lib/auth';

interface HeaderProps {
  locale?: string;
}

interface SiteSettings {
  site_name: string;
  logo_url: string | null;
}

export default function Header({ locale: localeProp }: HeaderProps = {}) {
  const t = useTranslations('common');
  const localeFromHook = useLocale();
  const pathname = usePathname();
  const router = useRouter();
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isLanguageMenuOpen, setIsLanguageMenuOpen] = useState(false);
  const [settings, setSettings] = useState<SiteSettings>({
    site_name: 'Este Nómada',
    logo_url: null,
  });
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  
  // Определяем текущую локаль: сначала из prop, потом из pathname, потом из hook
  const getCurrentLocale = (): Locale => {
    if (localeProp && locales.includes(localeProp as Locale)) {
      return localeProp as Locale;
    }
    const pathLocale = pathname.split('/')[1];
    if (locales.includes(pathLocale as Locale)) {
      return pathLocale as Locale;
    }
    return localeFromHook as Locale;
  };
  
  const locale = getCurrentLocale();

  // Функция проверки авторизации
  const checkAuth = useCallback(async () => {
    try {
      // Небольшая задержка для гарантии, что localStorage доступен
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Проверяем наличие токена перед запросом
      if (!hasToken()) {
        console.log('[Header] No token found');
        setIsAuthenticated(false);
        return;
      }
      
      console.log('[Header] Token found, checking auth');
      const apiUrl = typeof window !== 'undefined' 
        ? window.location.origin + '/api'
        : '/api';
      const response = await fetchWithAuth(`${apiUrl}/customers/`);
      if (response.ok) {
        const customers = await response.json();
        const isAuth = customers && customers.length > 0;
        console.log('[Header] Auth check result:', isAuth);
        setIsAuthenticated(isAuth);
      } else {
        console.log('[Header] Auth check failed:', response.status);
        setIsAuthenticated(false);
      }
    } catch (error) {
      console.error('[Header] Error checking auth:', error);
      setIsAuthenticated(false);
    }
  }, []);

  // Загружаем настройки сайта и проверяем авторизацию
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const response = await fetch('/api/settings/public/');
        const data = await response.json();
        setSettings({
          site_name: data.site_name || 'Este Nómada',
          logo_url: data.logo_url || null,
        });
      } catch (error) {
        console.error('[Header] Error fetching settings:', error);
      }
    };
    
    fetchSettings();
    checkAuth();
    
    // Проверяем авторизацию при изменении фокуса окна (возврат на вкладку)
    const handleFocus = () => {
      checkAuth();
    };
    window.addEventListener('focus', handleFocus);
    
    return () => {
      window.removeEventListener('focus', handleFocus);
    };
  }, [checkAuth]);

  useEffect(() => {
    // Проверяем, что мы на клиенте
    if (typeof window === 'undefined') return;
    
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    
    // Устанавливаем начальное состояние
    handleScroll();
    
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Закрываем меню языков при клике вне его
  useEffect(() => {
    if (!isLanguageMenuOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      if (!target.closest('.language-switcher-container')) {
        setIsLanguageMenuOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isLanguageMenuOpen]);

  // Закрываем меню языков при изменении локали
  useEffect(() => {
    setIsLanguageMenuOpen(false);
  }, [locale]);

  const switchLocale = (newLocale: Locale) => {
    // Сохраняем выбранную локаль в куки
    document.cookie = `NEXT_LOCALE=${newLocale}; path=/; max-age=${60 * 60 * 24 * 365}; SameSite=Lax`;
    
    // Получаем путь без префикса локали
    let pathWithoutLocale = pathname;
    
    // Убираем префикс текущей локали, если он есть
    for (const loc of locales) {
      if (pathname.startsWith(`/${loc}/`) || pathname === `/${loc}`) {
        pathWithoutLocale = pathname.replace(`/${loc}`, '') || '/';
        break;
      }
    }
    
    // Если путь пустой или это корень, просто переключаемся на новую локаль
    const newPath = pathWithoutLocale === '/' 
      ? `/${newLocale}` 
      : `/${newLocale}${pathWithoutLocale}`;
    
    // Используем полную перезагрузку страницы для гарантированного обновления локали
    window.location.href = newPath;
  };

  return (
    <motion.header
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? "bg-sand-100/80 backdrop-blur-md shadow-md"
          : "bg-sand-100/85 backdrop-blur-sm"
      }`}
    >
      <nav className="container mx-auto px-4 py-4 flex items-center justify-between">
        <Link href={`/${locale}`} className="flex items-center space-x-2">
          {settings.logo_url ? (
            <div className="w-10 h-10 rounded-full overflow-hidden bg-saffron-500 flex items-center justify-center">
              <img
                src={settings.logo_url}
                alt={settings.site_name}
                width={40}
                height={40}
                className="object-cover rounded-full"
                style={{ width: '40px', height: '40px' }}
              />
            </div>
          ) : (
            <div className="w-10 h-10 rounded-full overflow-hidden bg-saffron-500 flex items-center justify-center">
              <span className="text-white text-xl">EN</span>
            </div>
          )}
          <span className="text-xl font-semibold text-charcoal-900">
            {settings.site_name}
          </span>
        </Link>

        {/* Desktop Navigation */}
        <div className="hidden md:flex items-center space-x-6">
          <Link
            href={`/${locale}`}
            className="text-charcoal-700 hover:text-saffron-600 transition-colors font-medium"
          >
            {t('main')}
          </Link>
          <Link
            href={`/${locale}#about`}
            className="text-charcoal-700 hover:text-saffron-600 transition-colors font-medium"
          >
            {t('about')}
          </Link>
          <Link
            href={`/${locale}/stories`}
            className="text-charcoal-700 hover:text-saffron-600 transition-colors font-medium"
          >
            {t('stories')}
          </Link>
          <Link
            href={`/${locale}#menu`}
            className="text-charcoal-700 hover:text-saffron-600 transition-colors font-medium"
          >
            {t('ourDishes')}
          </Link>
          <Link
            href={`/${locale}/account`}
            onClick={async (e) => {
              // Проверяем токен перед переходом
              if (typeof window !== 'undefined') {
                const { getAccessToken } = await import('@/lib/auth');
                const token = getAccessToken();
                if (!token) {
                  // Если токена нет, проверяем еще раз
                  await checkAuth();
                }
              }
            }}
            className="px-6 py-2 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium"
          >
            {t('myAccount') || 'Мой ЛК'}
          </Link>
          <Link
            href={`/${locale}/order`}
            className="px-6 py-2 bg-charcoal-700 text-white rounded-full hover:bg-charcoal-800 transition-colors font-medium"
          >
            {t('order')}
          </Link>
        </div>

        {/* Language Switcher - Dropdown */}
        <div className="relative ml-4 border-l border-charcoal-300 pl-4 language-switcher-container">
          <button
            onClick={() => setIsLanguageMenuOpen(!isLanguageMenuOpen)}
            className="flex items-center space-x-2 px-3 py-1.5 rounded-md text-sm font-medium transition-all bg-saffron-500 text-white shadow-md hover:bg-saffron-600"
            aria-label="Select language"
          >
            <span className="text-lg">
              {locale === 'en' ? '🇬🇧' : locale === 'es' ? '🇪🇸' : '🇷🇺'}
            </span>
            <span className="hidden md:inline">{locale.toUpperCase()}</span>
            <svg
              className={`w-4 h-4 transition-transform ${isLanguageMenuOpen ? 'rotate-180' : ''}`}
              fill="none"
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {/* Dropdown Menu */}
          <AnimatePresence>
            {isLanguageMenuOpen && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.2 }}
                className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-warm-200 overflow-hidden z-50"
              >
                {locales.map((loc) => {
                  const flags: Record<Locale, string> = {
                    en: '🇬🇧',
                    es: '🇪🇸',
                    ru: '🇷🇺'
                  };
                  const names: Record<Locale, string> = {
                    en: 'English',
                    es: 'Español',
                    ru: 'Русский'
                  };
                  return (
                    <button
                      key={loc}
                      onClick={() => {
                        switchLocale(loc);
                        setIsLanguageMenuOpen(false);
                      }}
                      className={`w-full flex items-center space-x-3 px-4 py-3 text-left transition-colors ${
                        locale === loc
                          ? 'bg-saffron-50 text-saffron-600 font-medium'
                          : 'text-charcoal-700 hover:bg-saffron-50 hover:text-saffron-600'
                      }`}
                    >
                      <span className="text-xl">{flags[loc]}</span>
                      <span className="flex-1">{names[loc]}</span>
                      {locale === loc && (
                        <svg
                          className="w-5 h-5 text-saffron-500"
                          fill="currentColor"
                          viewBox="0 0 20 20"
                        >
                          <path
                            fillRule="evenodd"
                            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                            clipRule="evenodd"
                          />
                        </svg>
                      )}
                    </button>
                  );
                })}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Mobile Menu Button */}
        <button
          className="md:hidden text-charcoal-900"
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          aria-label="Toggle menu"
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
            {isMobileMenuOpen ? (
              <path d="M6 18L18 6M6 6l12 12" />
            ) : (
              <path d="M4 6h16M4 12h16M4 18h16" />
            )}
          </svg>
        </button>
      </nav>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden bg-sand-100/95 backdrop-blur-md border-t border-warm-200"
          >
            <div className="container mx-auto px-4 py-4 space-y-3">
              <Link
                href={`/${locale}`}
                className="block text-charcoal-700 hover:text-saffron-600 transition-colors font-medium py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {t('main')}
              </Link>
              <Link
                href={`/${locale}#about`}
                className="block text-charcoal-700 hover:text-saffron-600 transition-colors font-medium py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {t('about')}
              </Link>
              <Link
                href={`/${locale}/stories`}
                className="block text-charcoal-700 hover:text-saffron-600 transition-colors font-medium py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {t('stories')}
              </Link>
              <Link
                href={`/${locale}#menu`}
                className="block text-charcoal-700 hover:text-saffron-600 transition-colors font-medium py-2"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {t('ourDishes')}
              </Link>
              <Link
                href={`/${locale}/order`}
                onClick={() => setIsMobileMenuOpen(false)}
                className="w-full px-6 py-2 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium text-center block"
              >
                {t('order')}
              </Link>
              {isAuthenticated && (
              <Link
                href={`/${locale}/account`}
                onClick={async (e) => {
                  setIsMobileMenuOpen(false);
                  // Проверяем токен перед переходом
                  if (typeof window !== 'undefined') {
                    const { getAccessToken } = await import('@/lib/auth');
                    const token = getAccessToken();
                    if (!token) {
                      // Если токена нет, проверяем еще раз
                      await checkAuth();
                    }
                  }
                }}
                className="w-full px-6 py-2 bg-charcoal-700 text-white rounded-full hover:bg-charcoal-800 transition-colors font-medium text-center block mt-2"
              >
                {t('account')}
              </Link>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.header>
  );
}

