import Link from "next/link";

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-sand-50">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-charcoal-900 mb-4">404</h1>
        <p className="text-xl text-charcoal-600 mb-8">Страница не найдена</p>
        <Link
          href="/"
          className="inline-block px-6 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors"
        >
          Вернуться на главную
        </Link>
      </div>
    </div>
  );
}




