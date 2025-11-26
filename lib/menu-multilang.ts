import { query } from './db';
import { type Locale } from '@/lib/locales';

export interface MenuItemTranslation {
  id: number;
  menu_item_id: number;
  locale: string;
  name: string;
  description: string | null;
  category: string;
}

export interface MenuItem {
  id: number;
  price: number | null;
  image: string | null;
  order: number;
  active: boolean;
  // Переводы
  name: string;
  description: string | null;
  category: string;
}

/**
 * Получает элементы меню для указанной локали
 */
export async function getMenuItems(locale: Locale): Promise<MenuItem[]> {
  try {
    const items = await query<any[]>(
      `SELECT 
        mi.id,
        mi.price,
        mi.image,
        mi.\`order\`,
        mi.active,
        COALESCE(mit.name, mi.name) as name,
        COALESCE(mit.description, mi.description) as description,
        COALESCE(mit.category, mi.category) as category
      FROM menu_items mi
      LEFT JOIN menu_item_translations mit ON mi.id = mit.menu_item_id AND mit.locale = ?
      WHERE mi.active = TRUE
      ORDER BY mi.\`order\` ASC, name ASC`,
      [locale]
    );

    return items.map(item => ({
      id: item.id,
      price: item.price,
      image: item.image,
      order: item.order,
      active: item.active,
      name: item.name || '',
      description: item.description,
      category: item.category || '',
    }));
  } catch (error) {
    console.error('[Menu] Error fetching menu items:', error);
    return [];
  }
}

/**
 * Сохраняет перевод элемента меню
 */
export async function saveMenuItemTranslation(
  menuItemId: number,
  locale: Locale,
  name: string,
  description: string | null,
  category: string
): Promise<void> {
  await query(
    `INSERT INTO menu_item_translations (menu_item_id, locale, name, description, category)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE 
       name = VALUES(name),
       description = VALUES(description),
       category = VALUES(category),
       updated_at = CURRENT_TIMESTAMP`,
    [menuItemId, locale, name, description, category]
  );
}

