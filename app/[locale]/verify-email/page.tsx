"use client";

import { useState, useEffect, Suspense } from "react";
import { useTranslations, useLocale } from 'next-intl';
import { useSearchParams } from 'next/navigation';
import { motion } from "framer-motion";
import { CheckCircle, XCircle, Loader2 } from 'lucide-react';
import { getApiUrl } from '@/lib/get-api-url';
import Link from 'next/link';

// Делаем страницу динамической, так как она использует query параметры
export const dynamic = 'force-dynamic';

interface VerifyResponse {
  success: boolean;
  message?: string;
  error?: string;
  already_verified?: boolean;
  customer_name?: string;
  locale?: string;
}

function VerifyEmailContent() {
  const t = useTranslations('verifyEmail');
  const locale = useLocale();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<'loading' | 'success' | 'error' | 'already_verified'>('loading');
  const [message, setMessage] = useState<string>('');
  const [customerName, setCustomerName] = useState<string | null>(null);
  
  const API_BASE_URL = getApiUrl();
  const token = searchParams.get('token');

  useEffect(() => {
    if (!token) {
      setStatus('error');
      setMessage(t('noToken'));
      return;
    }

    const verifyEmail = async () => {
      try {
        const response = await fetch(
          `${API_BASE_URL}/customers/verify-email/?token=${token}&locale=${locale}`,
          {
            method: 'GET',
            credentials: 'include',
          }
        );

        const data: VerifyResponse = await response.json();

        if (response.ok && data.success) {
          if (data.already_verified) {
            setStatus('already_verified');
            setMessage(t('alreadyVerified'));
          } else {
            setStatus('success');
            setMessage(t('success'));
            if (data.customer_name) {
              setCustomerName(data.customer_name);
            }
          }
        } else {
          setStatus('error');
          setMessage(data.error || t('error'));
        }
      } catch (err) {
        console.error("Error verifying email:", err);
        setStatus('error');
        setMessage(t('error'));
      }
    };

    verifyEmail();
  }, [token, locale, API_BASE_URL, t]);

  return (
    <div className="min-h-screen bg-sand-50 py-20">
      <div className="container mx-auto px-4 max-w-2xl">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="bg-white rounded-2xl shadow-lg p-8 md:p-12"
        >
          {status === 'loading' && (
            <div className="text-center">
              <Loader2 className="w-16 h-16 text-saffron-500 animate-spin mx-auto mb-6" />
              <h1 className="text-3xl md:text-4xl font-bold text-charcoal-900 mb-4">
                {t('verifying')}
              </h1>
              <p className="text-charcoal-600 text-lg">
                {t('pleaseWait')}
              </p>
            </div>
          )}

          {status === 'success' && (
            <div className="text-center">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ type: "spring", stiffness: 200, damping: 15 }}
              >
                <CheckCircle className="w-20 h-20 text-green-500 mx-auto mb-6" />
              </motion.div>
              <h1 className="text-3xl md:text-4xl font-bold text-charcoal-900 mb-4">
                {t('successTitle')}
              </h1>
              {customerName && (
                <p className="text-xl text-charcoal-700 mb-4">
                  {t('greeting', { name: customerName })}
                </p>
              )}
              <p className="text-charcoal-600 text-lg mb-8">
                {message || t('successMessage')}
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link
                  href={`/${locale}/account`}
                  className="px-8 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium text-lg"
                >
                  {t('goToAccount')}
                </Link>
                <Link
                  href={`/${locale}`}
                  className="px-8 py-3 bg-warm-200 text-charcoal-700 rounded-full hover:bg-warm-300 transition-colors font-medium text-lg"
                >
                  {t('goToHome')}
                </Link>
              </div>
            </div>
          )}

          {status === 'already_verified' && (
            <div className="text-center">
              <CheckCircle className="w-20 h-20 text-blue-500 mx-auto mb-6" />
              <h1 className="text-3xl md:text-4xl font-bold text-charcoal-900 mb-4">
                {t('alreadyVerifiedTitle')}
              </h1>
              <p className="text-charcoal-600 text-lg mb-8">
                {message || t('alreadyVerifiedMessage')}
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link
                  href={`/${locale}/account`}
                  className="px-8 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium text-lg"
                >
                  {t('goToAccount')}
                </Link>
                <Link
                  href={`/${locale}`}
                  className="px-8 py-3 bg-warm-200 text-charcoal-700 rounded-full hover:bg-warm-300 transition-colors font-medium text-lg"
                >
                  {t('goToHome')}
                </Link>
              </div>
            </div>
          )}

          {status === 'error' && (
            <div className="text-center">
              <XCircle className="w-20 h-20 text-red-500 mx-auto mb-6" />
              <h1 className="text-3xl md:text-4xl font-bold text-charcoal-900 mb-4">
                {t('errorTitle')}
              </h1>
              <p className="text-charcoal-600 text-lg mb-8">
                {message || t('errorMessage')}
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link
                  href={`/${locale}`}
                  className="px-8 py-3 bg-saffron-500 text-white rounded-full hover:bg-saffron-600 transition-colors font-medium text-lg"
                >
                  {t('goToHome')}
                </Link>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-sand-50 py-20">
        <div className="container mx-auto px-4 max-w-2xl">
          <div className="bg-white rounded-2xl shadow-lg p-8 md:p-12 text-center">
            <Loader2 className="w-16 h-16 text-saffron-500 animate-spin mx-auto mb-6" />
            <p className="text-charcoal-600 text-lg">Загрузка...</p>
          </div>
        </div>
      </div>
    }>
      <VerifyEmailContent />
    </Suspense>
  );
}

