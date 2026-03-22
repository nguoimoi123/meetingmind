import { useEffect, useState } from 'react';
import LoginScreen from './components/LoginScreen';
import AdminDashboard from './components/AdminDashboard';
import { apiRequest } from './lib/api';
import { clearAuth, readAuth } from './lib/storage';

export default function App() {
  const [authChecked, setAuthChecked] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    let active = true;

    async function bootstrap() {
      const auth = readAuth();
      if (!auth.backendBaseUrl || !auth.adminKey) {
        if (active) {
          setAuthChecked(true);
        }
        return;
      }

      try {
        await apiRequest('/admin/api/auth/me');
        if (active) {
          setIsAuthenticated(true);
        }
      } catch (_) {
        clearAuth();
        if (active) {
          setIsAuthenticated(false);
        }
      } finally {
        if (active) {
          setAuthChecked(true);
        }
      }
    }

    bootstrap();
    return () => {
      active = false;
    };
  }, []);

  if (!authChecked) {
    return (
      <div className="login-shell">
        <div className="login-card glass">
          <div className="badge">MeetingMind Admin React</div>
          <h1 className="page-title">Dang tai...</h1>
          <p className="muted">Dang kiem tra phien dang nhap admin.</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginScreen onLoggedIn={() => setIsAuthenticated(true)} />;
  }

  return <AdminDashboard onLoggedOut={() => setIsAuthenticated(false)} />;
}
