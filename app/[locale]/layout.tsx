import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';
import Script from 'next/script';
import { locales, defaultLocale } from '@/lib/locales';
import Header from '@/components/Header';
import Footer from '@/components/Footer';
import VersionLogger from '@/components/VersionLogger';
import CookiebotLoader from '@/components/CookiebotLoader';

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export const metadata = {
  title: "Este Nómada",
  description: "Eastern cuisine, born on the road",
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.png', type: 'image/png' },
    ],
    apple: '/favicon.png',
  },
  verification: {
    google: 'Y1AyqkyJ7XtgPPzt1PY7-9zbXiy1eJCQuXgHyI6bNmE',
  },
};

export default async function LocaleLayout({
  children,
  params: { locale: localeParam }
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  // Убеждаемся, что locale валиден - middleware должен гарантировать это
  const locale = locales.includes(localeParam as any) ? localeParam : defaultLocale;
  
  console.log('[LocaleLayout] Rendering for locale:', locale, 'original:', localeParam);

  let messages;
  try {
    console.log('[LocaleLayout] Loading messages for locale:', locale);
    // Используем getMessages с явным указанием locale
    messages = await getMessages({ locale });
    console.log('[LocaleLayout] Messages loaded successfully');
  } catch (error) {
    console.error('[LocaleLayout] Error loading messages:', error);
    // Fallback to empty messages if loading fails
    messages = {};
  }

  return (
    <>
      {/* Cookiebot - должен загружаться первым для блокировки других скриптов */}
      <CookiebotLoader />
      {/* Google Tag Manager - отложенная загрузка для улучшения производительности */}
      <Script
        id="gtm-script"
        strategy="lazyOnload"
        dangerouslySetInnerHTML={{
          __html: `(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;
try{
  if(f&&f.parentNode&&!f.parentNode.contains(j)){f.parentNode.insertBefore(j,f);}
  else if(d.head&&!d.head.contains(j)){d.head.appendChild(j);}
  else if(d.body&&!d.body.contains(j)){d.body.appendChild(j);}
}catch(e){console.error('GTM script insertion error:',e);}
})(window,document,'script','dataLayer','GTM-NRCNBX5S');`,
        }}
      />
      {/* Google Analytics - отложенная загрузка */}
      <Script
        src="https://www.googletagmanager.com/gtag/js?id=G-0V473MDDMV"
        strategy="lazyOnload"
      />
      <Script
        id="gtag-init"
        strategy="lazyOnload"
        dangerouslySetInnerHTML={{
          __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('config', 'G-0V473MDDMV');
            `,
        }}
      />
      {/* Google Tag Manager (noscript) */}
      <noscript>
        <iframe
          src="https://www.googletagmanager.com/ns.html?id=GTM-NRCNBX5S"
          height="0"
          width="0"
          style={{ display: 'none', visibility: 'hidden' }}
        />
      </noscript>
      <NextIntlClientProvider messages={messages} locale={locale}>
        <VersionLogger />
        <Header locale={locale} />
        <main className="min-h-screen">
          {children}
        </main>
        <Footer locale={locale} />
      </NextIntlClientProvider>
    </>
  );
}
