import Hero from "@/components/sections/Hero";
import AboutBrand from "@/components/sections/AboutBrand";
import MenuWrapper from "@/components/sections/MenuWrapper";
import StoriesWrapper from "@/components/sections/StoriesWrapper";
import PathMap from "@/components/sections/PathMap";
import CustomSections from "@/components/sections/CustomSections";
import { locales, defaultLocale, type Locale } from '@/lib/locales';

// Временно уменьшаем revalidate для получения актуальных данных
export const revalidate = 60; // Регенерируем страницу каждую минуту

export default async function Home({ params }: { params: { locale: string } }) {
  console.log('[Home] Rendering home page with params.locale:', params.locale);
  // Используем params.locale напрямую, как в layout.tsx
  const locale: Locale = (locales.includes(params.locale as Locale) ? params.locale : defaultLocale) as Locale;
  console.log('[Home] Current locale:', locale);
  
  return (
    <>
      <Hero locale={locale} />
      <AboutBrand />
      <MenuWrapper locale={locale} />
      <StoriesWrapper locale={locale} />
      <PathMap />
      <CustomSections />
    </>
  );
}

