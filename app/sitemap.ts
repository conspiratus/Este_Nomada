import { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrls = [
    'https://estenomada.es',
    'https://nomadadeleste.es',
    'https://nomadadeleste.com',
  ];

  const locales = ['ru', 'en', 'es'];
  const routes = ['', '/stories'];

  const urls: MetadataRoute.Sitemap = [];

  baseUrls.forEach((baseUrl) => {
    locales.forEach((locale) => {
      routes.forEach((route) => {
        urls.push({
          url: `${baseUrl}/${locale}${route}`,
          lastModified: new Date(),
          changeFrequency: route === '' ? 'daily' : 'weekly',
          priority: route === '' ? 1 : 0.8,
        });
      });
    });
  });

  return urls;
}

