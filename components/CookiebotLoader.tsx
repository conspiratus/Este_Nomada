"use client";

import { useEffect } from 'react';

/**
 * Определяет Cookiebot ID на основе текущего домена.
 * Для каждого домена нужно создать отдельную группу в Cookiebot Manager
 * или добавить домен в существующую группу.
 */
function getCookiebotId(): string | null {
  if (typeof window === 'undefined') return null;
  
  const hostname = window.location.hostname.toLowerCase();
  
  // Маппинг доменов на Cookiebot ID
  // Для каждого домена нужно получить свой ID из Cookiebot Manager
  const domainToCookiebotId: Record<string, string> = {
    'estenomada.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a',
    'www.estenomada.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a',
    'nomadadeleste.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID после создания группы
    'www.nomadadeleste.es': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID после создания группы
    'nomadadeleste.com': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID после создания группы
    'www.nomadadeleste.com': 'fb8cae82-2ca6-40a3-b51c-29c68530a64a', // TODO: Замени на реальный ID после создания группы
  };
  
  // Возвращаем ID для текущего домена или null, если домен не найден
  return domainToCookiebotId[hostname] || null;
}

export default function CookiebotLoader() {
  useEffect(() => {
    // Проверяем, не загружен ли уже скрипт Cookiebot
    if (typeof window === 'undefined') return;
    
    // Получаем Cookiebot ID для текущего домена
    const cookiebotId = getCookiebotId();
    if (!cookiebotId) {
      console.warn('[CookiebotLoader] No Cookiebot ID configured for domain:', window.location.hostname);
      return;
    }
    
    // Проверяем, не загружен ли Cookiebot через GTM или другой способ
    if ((window as any).Cookiebot) {
      console.log('[CookiebotLoader] Cookiebot already initialized, skipping');
      return;
    }
    
    // Проверяем, есть ли уже скрипт Cookiebot в DOM
    const existingScript = document.querySelector('script[id="Cookiebot"], script[src*="cookiebot.com"]');
    if (existingScript) {
      console.log('[CookiebotLoader] Cookiebot script already exists in DOM, skipping');
      return;
    }

    // Проверяем, не загружается ли Cookiebot через GTM (ждем немного)
    let checkGTM: NodeJS.Timeout | null = null;
    
    const loadCookiebot = () => {
      // Проверяем еще раз перед загрузкой
      if ((window as any).Cookiebot) {
        console.log('[CookiebotLoader] Cookiebot already loaded, skipping');
        return;
      }
      
      const existingScript = document.querySelector('script[id="Cookiebot"], script[src*="cookiebot.com"]');
      if (existingScript) {
        console.log('[CookiebotLoader] Cookiebot script already exists, skipping');
        return;
      }
      
      // Если через GTM не загрузился, загружаем вручную
      try {
        // Проверяем еще раз, что скрипт не существует
        if (document.querySelector('script[id="Cookiebot"], script[src*="cookiebot.com"]')) {
          console.log('[CookiebotLoader] Cookiebot script already exists, skipping');
          return;
        }
        
        const script = document.createElement('script');
        script.id = 'Cookiebot';
        script.src = 'https://consent.cookiebot.com/uc.js';
        script.setAttribute('data-cbid', cookiebotId);
        script.setAttribute('data-blockingmode', 'auto');
        script.async = true;
        
        // Проверяем, что head существует, не содержит уже такой скрипт, и скрипт еще не добавлен
        if (document.head && !document.head.querySelector(`script[id="Cookiebot"]`) && !document.head.contains(script)) {
          document.head.appendChild(script);
          console.log('[CookiebotLoader] Cookiebot script loaded manually for domain:', window.location.hostname);
        } else {
          console.log('[CookiebotLoader] Cookiebot script already in DOM or head not available');
        }
      } catch (error) {
        console.error('[CookiebotLoader] Error loading Cookiebot script:', error);
      }
    };
    
    checkGTM = setTimeout(loadCookiebot, 1500); // Увеличиваем время ожидания

    return () => {
      if (checkGTM) {
        clearTimeout(checkGTM);
      }
    };
  }, []);

  return null;
}

