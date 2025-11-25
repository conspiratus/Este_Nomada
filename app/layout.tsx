// Root layout для next-intl с App Router
// Для next-intl с App Router корневой layout должен быть максимально минимальным
// html/body создаются в [locale]/layout.tsx
export const metadata = {
  icons: {
    icon: [
      { url: '/favicon.ico', sizes: 'any' },
      { url: '/favicon.png', type: 'image/png' },
    ],
    apple: '/favicon.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Для next-intl с App Router root layout должен возвращать children
  // html/body создаются в [locale]/layout.tsx
  // Используем Fragment для правильной структуры React
  return <>{children}</>;
}

