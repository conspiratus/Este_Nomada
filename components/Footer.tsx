"use client";

import { useEffect, useState } from 'react';
import Link from "next/link";
import Image from "next/image";
import { useTranslations, useLocale } from 'next-intl';

interface FooterProps {
  locale?: string;
}

interface FooterSection {
  id: number;
  title: string;
  content: string;
  position: 'left' | 'center' | 'right';
  text_align: 'left' | 'center' | 'right' | 'justify';
  order: number;
}

interface SiteSettings {
  site_name: string;
  logo_url: string | null;
}

export default function Footer({ locale: localeProp }: FooterProps = {}) {
  const t = useTranslations('footer');
  const localeFromHook = useLocale();
  const locale = localeProp || localeFromHook;
  const [sections, setSections] = useState<FooterSection[]>([]);
  const [loading, setLoading] = useState(true);
  const [siteSettings, setSiteSettings] = useState<SiteSettings>({
    site_name: 'Este Nómada',
    logo_url: null,
  });
  
  // Загружаем настройки сайта для логотипа
  useEffect(() => {
    const fetchSiteSettings = async () => {
      try {
        const response = await fetch('/api/settings/public/');
        const data = await response.json();
        setSiteSettings({
          site_name: data.site_name || 'Este Nómada',
          logo_url: data.logo_url || null,
        });
      } catch (error) {
        console.error('[Footer] Error fetching site settings:', error);
      }
    };
    fetchSiteSettings();
  }, []);

  useEffect(() => {
    const fetchFooterSections = async () => {
      try {
        const response = await fetch(`/api/footer/?locale=${locale}`);
        const data = await response.json();
        setSections(data.results || []);
      } catch (error) {
        console.error('[Footer] Error fetching footer sections:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchFooterSections();
  }, [locale]);

  // Функция для декодирования HTML сущностей (включая числовые)
  const decodeHtmlEntities = (text: string): string => {
    if (!text) return text;
    
    // Используем браузерный API если доступен (работает лучше всего)
    if (typeof window !== 'undefined' && typeof document !== 'undefined') {
      const textarea = document.createElement('textarea');
      textarea.innerHTML = text;
      let decoded = textarea.value;
      
      // Декодируем рекурсивно, пока есть изменения (на случай двойного экранирования)
      let iterations = 0;
      while (decoded.includes('&lt;') || decoded.includes('&gt;') || decoded.includes('&amp;')) {
        if (iterations >= 5) break; // Защита от бесконечного цикла
        textarea.innerHTML = decoded;
        decoded = textarea.value;
        iterations++;
      }
      
      return decoded;
    }
    
    // Fallback для SSR: декодируем вручную
    const entities: { [key: string]: string } = {
      '&lt;': '<',
      '&gt;': '>',
      '&amp;': '&',
      '&quot;': '"',
      '&#39;': "'",
      '&#x27;': "'",
      '&#x2F;': '/',
      '&nbsp;': ' ',
      '&apos;': "'",
    };
    
    let result = text;
    let previousResult = '';
    let iterations = 0;
    const maxIterations = 5;
    
    while (result !== previousResult && iterations < maxIterations) {
      previousResult = result;
      
      // Декодируем числовые сущности
      result = result.replace(/&#(\d+);/g, (match, dec) => {
        return String.fromCharCode(parseInt(dec, 10));
      });
      result = result.replace(/&#x([0-9A-Fa-f]+);/gi, (match, hex) => {
        return String.fromCharCode(parseInt(hex, 16));
      });
      
      // Декодируем именованные сущности
      result = result.replace(/&[#\w]+;/g, (entity) => {
        return entities[entity] || entity;
      });
      
      iterations++;
    }
    
    return result;
  };

  // Функция для замены /logo_EN.png на логотип из настроек
  const replaceLogoInContent = (content: string): string => {
    if (!content) return content;
    
    // Декодируем HTML сущности (на случай если они экранированы)
    let result = decodeHtmlEntities(content);
    
    if (!siteSettings.logo_url) return result;
    
    // Заменяем полные URL с протоколом (https:// или http://)
    result = result.replace(/https?:\/\/[^"'\s<>]+\/logo_EN\.png/gi, siteSettings.logo_url);
    
    // Заменяем URL без протокола (//domain.com/logo_EN.png)
    result = result.replace(/\/\/[^"'\s<>]+\/logo_EN\.png/gi, siteSettings.logo_url);
    
    // Заменяем относительные пути (/logo_EN.png)
    result = result.replace(/\/logo_EN\.png/gi, siteSettings.logo_url);
    
    return result;
  };
  
  // Группируем секции по позициям
  const leftSections = sections.filter(s => s.position === 'left');
  const centerSections = sections.filter(s => s.position === 'center');
  const rightSections = sections.filter(s => s.position === 'right');
  
  return (
    <footer id="contacts" className="bg-charcoal-900 text-sand-100 py-12">
      <div className="container mx-auto px-4">
        {!loading && sections.length > 0 && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            {/* Left */}
            <div className="space-y-6">
              {leftSections.map(section => (
                <div key={section.id} style={{ textAlign: section.text_align }}>
                  {section.title && (
                    <h3 
                      className="font-semibold mb-4"
                      dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.title) }}
                    />
                  )}
                  <div 
                    className="text-sand-300 text-sm prose prose-invert max-w-none"
                    dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.content) }}
                  />
                </div>
              ))}
            </div>

            {/* Center */}
            <div className="space-y-6">
              {centerSections.map(section => (
                <div key={section.id} style={{ textAlign: section.text_align }}>
                  {section.title && (
                    <h3 
                      className="font-semibold mb-4"
                      dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.title) }}
                    />
                  )}
                  <div 
                    className="text-sand-300 text-sm prose prose-invert max-w-none"
                    dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.content) }}
                  />
                </div>
              ))}
            </div>

            {/* Right */}
            <div className="space-y-6">
              {rightSections.map(section => (
                <div key={section.id} style={{ textAlign: section.text_align }}>
                  {section.title && (
                    <h3 
                      className="font-semibold mb-4"
                      dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.title) }}
                    />
                  )}
                  <div 
                    className="text-sand-300 text-sm prose prose-invert max-w-none"
                    dangerouslySetInnerHTML={{ __html: replaceLogoInContent(section.content) }}
                  />
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </footer>
  );
}

