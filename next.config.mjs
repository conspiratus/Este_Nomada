import createMDX from '@next/mdx'
import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin('./i18n.ts');

/** @type {import('next').NextConfig} */
const nextConfig = {
  pageExtensions: ['ts', 'tsx', 'md', 'mdx'],
  reactStrictMode: true,
  // output: 'standalone', // Отключено, используем кастомный server.js
  images: {
    // Включаем оптимизацию изображений для лучшего сжатия
    unoptimized: false,
    // Качество сжатия по умолчанию (можно переопределить в компонентах)
    minimumCacheTTL: 60,
    remotePatterns: [
      {
        protocol: 'http',
        hostname: 'localhost',
        port: '3000',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
    // Оптимизация форматов изображений - WebP и AVIF для лучшего сжатия
    formats: ['image/avif', 'image/webp'],
    // Размеры устройств для адаптивных изображений
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
  trailingSlash: false,
  // Оптимизация производительности
  compress: true,
  poweredByHeader: false,
  // Исключаем mysql2 из серверного бандла (для standalone режима)
  experimental: {
    serverComponentsExternalPackages: ['mysql2'],
    optimizePackageImports: ['framer-motion', 'next-intl'],
  },
  // Оптимизация CSS - минификация и оптимизация
  swcMinify: true,
  // Оптимизация компиляции
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production' ? {
      exclude: ['error', 'warn'],
    } : false,
  },
}

const withMDX = createMDX({
  options: {
    remarkPlugins: [],
    rehypePlugins: [],
  },
})

export default withNextIntl(withMDX(nextConfig))

