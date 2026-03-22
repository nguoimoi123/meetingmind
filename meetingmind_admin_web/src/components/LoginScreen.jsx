import { useMemo, useState } from 'react';
import { getDefaultBackendUrl } from '../lib/api';
import { saveAuth } from '../lib/storage';

export default function LoginScreen({ onLoggedIn }) {
  const defaultBaseUrl = useMemo(() => getDefaultBackendUrl(), []);
  const [backendBaseUrl, setBackendBaseUrl] = useState(defaultBaseUrl);
  const [adminKey, setAdminKey] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');

    if (!backendBaseUrl.trim() || !adminKey.trim()) {
      setError('Backend URL va admin key la bat buoc.');
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await fetch(`${backendBaseUrl.trim()}/admin/api/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Key': adminKey.trim(),
        },
        body: JSON.stringify({ admin_key: adminKey.trim() }),
      });
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || 'Login failed');
      }

      saveAuth({
        backendBaseUrl: backendBaseUrl.trim(),
        adminKey: adminKey.trim(),
      });
      onLoggedIn({
        backendBaseUrl: backendBaseUrl.trim(),
        adminKey: adminKey.trim(),
      });
    } catch (submitError) {
      setError(submitError.message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="login-shell">
      <div className="login-card glass">
        <div className="badge">MeetingMind Admin React</div>
        <h1 className="page-title">Secure Upgrade Control</h1>
        <p className="muted">
          Dang nhap de quan ly giao dich VNPAY, issue code, resend code va revoke
          code cho nguoi dung.
        </p>

        <form className="stack-md" onSubmit={handleSubmit}>
          <label className="field-label" htmlFor="backendBaseUrl">
            Backend Base URL
          </label>
          <input
            id="backendBaseUrl"
            value={backendBaseUrl}
            onChange={(event) => setBackendBaseUrl(event.target.value)}
            placeholder="http://localhost:5000"
          />

          <label className="field-label" htmlFor="adminKey">
            Admin Key
          </label>
          <input
            id="adminKey"
            type="password"
            value={adminKey}
            onChange={(event) => setAdminKey(event.target.value)}
            placeholder="Nhap admin key"
          />

          {error ? <div className="error-box">{error}</div> : null}

          <button type="submit" disabled={isSubmitting}>
            {isSubmitting ? 'Dang dang nhap...' : 'Dang nhap'}
          </button>
        </form>
      </div>
    </div>
  );
}
