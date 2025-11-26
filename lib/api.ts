/**
 * API клиент для работы с Django бэкендом.
 */
import { getApiUrl } from './get-api-url';

const API_BASE_URL = getApiUrl();

interface ApiResponse<T> {
  data?: T;
  error?: string;
}

class ApiClient {
  private baseUrl: string;
  private token: string | null = null;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
    if (typeof window !== 'undefined') {
      this.token = this.getTokenFromStorage();
    }
  }

  private getTokenFromStorage(): string | null {
    if (typeof document === 'undefined') return null;
    const cookies = document.cookie.split(';');
    for (const cookie of cookies) {
      const [name, value] = cookie.trim().split('=');
      if (name === 'access_token') {
        return decodeURIComponent(value);
      }
    }
    return null;
  }

  setToken(token: string | null) {
    this.token = token;
    if (token && typeof document !== 'undefined') {
      document.cookie = `access_token=${token}; path=/; max-age=${60 * 60 * 24 * 7}; SameSite=Lax`;
    } else if (typeof document !== 'undefined') {
      document.cookie = 'access_token=; path=/; max-age=0';
    }
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${endpoint}`;
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (this.token) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${this.token}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
        credentials: 'include',
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
        return { error: errorData.error || `HTTP ${response.status}` };
      }

      const data = await response.json();
      return { data };
    } catch (error: any) {
      return { error: error.message || 'Network error' };
    }
  }

  // Auth methods
  async login(username: string, password: string) {
    const response = await this.request<{ access: string; refresh: string }>(
      '/auth/login/',
      {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      }
    );

    if (response.data) {
      this.setToken(response.data.access);
      return { success: true, token: response.data.access };
    }

    return { success: false, error: response.error };
  }

  async logout() {
    this.setToken(null);
    return { success: true };
  }

  async checkAuth() {
    const response = await this.request('/auth/check/');
    return response.data !== undefined;
  }

  // Stories
  async getStories() {
    return this.request<any[]>('/stories/');
  }

  async getStory(slug: string) {
    return this.request<any>(`/stories/${slug}/`);
  }

  async createStory(data: any) {
    return this.request<any>('/stories/', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateStory(id: number, data: any) {
    return this.request<any>(`/stories/${id}/`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteStory(id: number) {
    return this.request(`/stories/${id}/`, {
      method: 'DELETE',
    });
  }

  // Menu
  async getMenu() {
    return this.request<any[]>('/menu/');
  }

  async getMenuItem(id: number) {
    return this.request<any>(`/menu/${id}/`);
  }

  async createMenuItem(data: any) {
    return this.request<any>('/menu/', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateMenuItem(id: number, data: any) {
    return this.request<any>(`/menu/${id}/`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async deleteMenuItem(id: number) {
    return this.request(`/menu/${id}/`, {
      method: 'DELETE',
    });
  }

  // Settings
  async getSettings() {
    return this.request<any>('/settings/');
  }

  async updateSettings(data: any) {
    return this.request<any>('/settings/', {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  // Orders
  async createOrder(data: any) {
    return this.request<any>('/orders/', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async getOrders() {
    return this.request<any[]>('/orders/');
  }

  // Instagram
  async getInstagramFeed() {
    return this.request<any[]>('/instagram/feed/');
  }
}

export const apiClient = new ApiClient(API_BASE_URL);

