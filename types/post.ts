export interface Post {
  id?: number;
  title: string;
  slug: string;
  date: string;
  excerpt?: string;
  coverImage?: string;
  cover_image?: string;
  content: string;
  source: "manual" | "telegram";
  published?: boolean;
}

