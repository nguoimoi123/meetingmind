import { clearAuth, readAuth } from './storage';

export function getDefaultBackendUrl() {
  return import.meta.env.VITE_BACKEND_BASE_URL || 'http://localhost:5000';
}

export async function apiRequest(path, options = {}) {
  const auth = readAuth();
  const backendBaseUrl = auth.backendBaseUrl || getDefaultBackendUrl();
  const adminKey = auth.adminKey || '';

  const response = await fetch(`${backendBaseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(adminKey ? { 'X-Admin-Key': adminKey } : {}),
      ...(options.headers || {}),
    },
  });

  const data = await response.json();
  if (!response.ok) {
    if (response.status === 401) {
      clearAuth();
    }
    throw new Error(data.error || 'Request failed');
  }
  return data;
}
