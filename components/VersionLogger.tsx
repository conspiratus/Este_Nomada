"use client";

import { useEffect } from 'react';
import { getAppVersion } from '@/lib/version';

export default function VersionLogger() {
  useEffect(() => {
    const version = getAppVersion();
    console.log(
      `%c Este Nómada v${version} `,
      'background: #D4A574; color: #2C2A29; padding: 4px 8px; border-radius: 4px; font-weight: bold;'
    );
  }, []);

  return null;
}


