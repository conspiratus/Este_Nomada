"use client";

import { motion } from "framer-motion";
import { useTranslations } from 'next-intl';

export default function PathMap() {
  const t = useTranslations('pathMap');
  
  return (
    <section className="py-20 bg-gradient-to-b from-sand-50 to-warm-100">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="text-center mb-12"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-charcoal-900 mb-4">
            {t('title')}
          </h2>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 1 }}
          className="max-w-4xl mx-auto"
        >
          {/* Placeholder для карты-плова */}
          <div className="relative aspect-video rounded-lg overflow-hidden shadow-2xl vintage-border bg-gradient-to-br from-saffron-300 via-warm-400 to-charcoal-700">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center text-white">
                <span className="text-8xl mb-4 block">🗺️</span>
                <p className="text-2xl font-semibold">{t('title')}</p>
              </div>
            </div>
            {/* Декоративные элементы для имитации карты */}
            <div className="absolute top-10 left-10 w-16 h-16 bg-white/20 rounded-full border-2 border-white/40" />
            <div className="absolute top-32 right-20 w-12 h-12 bg-white/20 rounded-full border-2 border-white/40" />
            <div className="absolute bottom-20 left-1/4 w-10 h-10 bg-white/20 rounded-full border-2 border-white/40" />
            <div className="absolute bottom-32 right-1/3 w-14 h-14 bg-white/20 rounded-full border-2 border-white/40" />
          </div>

          <motion.p
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.5, duration: 0.8 }}
            className="text-center text-xl md:text-2xl text-charcoal-700 mt-8 font-medium italic"
          >
            «{t('quote')}»
          </motion.p>
        </motion.div>
      </div>
    </section>
  );
}

