"use client";

import { useState, useEffect } from "react";
import { useTranslations, useLocale } from 'next-intl';
import { motion, AnimatePresence } from "framer-motion";
import { X, User, Mail, Phone, Lock } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { getApiUrl } from '@/lib/get-api-url';
import { saveTokens } from '@/lib/auth';

interface RegistrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  initialData?: {
    name?: string;
    email?: string;
    phone?: string;
  };
}

export default function RegistrationModal({ isOpen, onClose, onSuccess, initialData }: RegistrationModalProps) {
  const t = useTranslations('registration');
  const locale = useLocale();
  const router = useRouter();
  const [formData, setFormData] = useState({
    name: initialData?.name || '',
    email: initialData?.email || '',
    phone: initialData?.phone || '',
    password: '',
    passwordConfirm: '',
  });
  
  // Обновляем форму при изменении initialData
  useEffect(() => {
    if (initialData) {
      setFormData(prev => ({
        ...prev,
        name: initialData.name || prev.name,
        email: initialData.email || prev.email,
        phone: initialData.phone || prev.phone,
      }));
    }
  }, [initialData]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const API_BASE_URL = getApiUrl();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Валидация
    if (!formData.name || !formData.email || !formData.phone) {
      setError(t('allFieldsRequired') || 'Все поля обязательны для заполнения');
      return;
    }

    if (!formData.password || formData.password.length < 8) {
      setError(t('passwordMinLength') || 'Пароль должен содержать минимум 8 символов');
      return;
    }

    if (formData.password !== formData.passwordConfirm) {
      setError(t('passwordsDoNotMatch') || 'Пароли не совпадают');
      return;
    }

    setSubmitting(true);
    try {
      const response = await fetch(`${API_BASE_URL}/customers/register/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
          password: formData.password,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        
        // Сохраняем JWT токены, если они есть
        if (data.access && data.refresh) {
          saveTokens(data.access, data.refresh);
        }
        
        setSuccess(true);
        setTimeout(() => {
          // Перенаправляем в ЛК сразу после регистрации
          router.push(`/${locale}/account`);
          onClose();
          if (onSuccess) {
            onSuccess();
          }
        }, 1500);
      } else {
        const errorData = await response.json();
        setError(errorData.error || t('error'));
      }
    } catch (err) {
      console.error("Error registering:", err);
      setError(t('error'));
    } finally {
      setSubmitting(false);
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.9 }}
          className="bg-white rounded-2xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto"
        >
          <div className="p-6">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold text-charcoal-900">
                  {t('title')}
                </h2>
                <p className="text-sm text-charcoal-600 mt-1">
                  {t('subtitle')}
                </p>
              </div>
              <button
                onClick={onClose}
                className="p-2 hover:bg-sand-50 rounded-full transition-colors"
                aria-label={t('close')}
              >
                <X className="w-5 h-5 text-charcoal-600" />
              </button>
            </div>

            {success ? (
              <div className="text-center py-8">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-charcoal-900 mb-2">
                  {t('success')}
                </h3>
                <p className="text-charcoal-600">
                  {t('successMessage')}
                </p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Имя */}
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                    <User className="w-4 h-4 mr-1" />
                    {t('name')} *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('namePlaceholder')}
                  />
                </div>

                {/* Email */}
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                    <Mail className="w-4 h-4 mr-1" />
                    {t('email')} *
                  </label>
                  <input
                    type="email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('emailPlaceholder')}
                  />
                </div>

                {/* Телефон */}
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                    <Phone className="w-4 h-4 mr-1" />
                    {t('phone')} *
                  </label>
                  <input
                    type="tel"
                    required
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('phonePlaceholder')}
                  />
                </div>

                {/* Пароль */}
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                    <Lock className="w-4 h-4 mr-1" />
                    {t('password')} *
                  </label>
                  <input
                    type="password"
                    required
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('passwordPlaceholder')}
                  />
                </div>

                {/* Подтверждение пароля */}
                <div>
                  <label className="block text-sm font-medium text-charcoal-700 mb-2 flex items-center">
                    <Lock className="w-4 h-4 mr-1" />
                    {t('passwordConfirm')} *
                  </label>
                  <input
                    type="password"
                    required
                    value={formData.passwordConfirm}
                    onChange={(e) => setFormData({ ...formData, passwordConfirm: e.target.value })}
                    className="w-full px-4 py-3 rounded-lg border border-warm-300 focus:ring-2 focus:ring-saffron-500 focus:border-transparent outline-none"
                    placeholder={t('passwordConfirmPlaceholder')}
                  />
                </div>

                {error && (
                  <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                    <p className="text-sm text-red-600">{error}</p>
                  </div>
                )}

                <div className="flex space-x-3 pt-4">
                  <button
                    type="button"
                    onClick={onClose}
                    className="flex-1 px-4 py-3 border border-warm-300 text-charcoal-700 rounded-lg hover:bg-sand-50 transition-colors font-medium"
                  >
                    {t('skip')}
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="flex-1 px-4 py-3 bg-saffron-500 text-white rounded-lg hover:bg-saffron-600 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {submitting ? t('registering') : t('register')}
                  </button>
                </div>
              </form>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}

