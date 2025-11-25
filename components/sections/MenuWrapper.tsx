import Menu from './Menu';
import { getMenuItems } from '@/lib/menu-api';
import { defaultLocale, type Locale } from '@/lib/locales';

interface MenuWrapperProps {
  locale?: Locale;
}

export default async function MenuWrapper({ locale = defaultLocale }: MenuWrapperProps) {
  const menuItems = await getMenuItems(locale);
  console.log(`[MenuWrapper] Loaded ${menuItems.length} items for locale: ${locale}`);
  if (menuItems.length > 0) {
    console.log(`[MenuWrapper] First item:`, {
      name: menuItems[0].name,
      hasDescription: !!menuItems[0].description,
      descriptionPreview: menuItems[0].description ? menuItems[0].description.substring(0, 100) : 'None'
    });
  }
  return <Menu menuItems={menuItems} />;
}

