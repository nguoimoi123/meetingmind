import { useEffect, useMemo, useState } from 'react';
import { apiRequest } from '../lib/api';
import { clearAuth } from '../lib/storage';

const EMPTY_FILTERS = {
  search: '',
  plan: '',
  status: '',
  payment_status: '',
};

const EMPTY_STATS = {
  total: 0,
  paid_waiting_code: 0,
  codes_sent: 0,
  redeemed: 0,
};

function buildTxId() {
  return `TX-${Date.now()}`;
}

function StatusBadge({ value }) {
  const className = String(value || '').toLowerCase();
  return <span className={`status-badge ${className}`}>{value || '-'}</span>;
}

function MiniBarChart({ title, rows, valueKey, colorClass, subtitle }) {
  const maxValue = Math.max(...rows.map((row) => row[valueKey] || 0), 1);

  return (
    <div className="chart-card">
      <div className="chart-head">
        <div>
          <h3>{title}</h3>
          <div className="subtle">{subtitle}</div>
        </div>
      </div>
      <div className="chart-bars">
        {rows.map((row) => {
          const value = row[valueKey] || 0;
          const height = `${Math.max((value / maxValue) * 100, value > 0 ? 8 : 2)}%`;
          return (
            <div className="chart-bar-item" key={`${title}-${row.label || row.year}`}>
              <div className="chart-bar-wrap">
                <div className={`chart-bar ${colorClass}`} style={{ height }} title={`${row.label || row.year}: ${value}`} />
              </div>
              <div className="chart-bar-value">{value}</div>
              <div className="chart-bar-label">{row.label || row.year}</div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function ConfirmDialog({ open, title, description, confirmLabel, onCancel, onConfirm, loading }) {
  if (!open) {
    return null;
  }

  return (
    <div className="modal-backdrop">
      <div className="modal-card glass">
        <h3>{title}</h3>
        <p className="muted">{description}</p>
        <div className="hero-actions top-space">
          <button className="ghost narrow" onClick={onCancel} disabled={loading}>
            Huy
          </button>
          <button className="narrow danger-button" onClick={onConfirm} disabled={loading}>
            {loading ? 'Dang xu ly...' : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function AdminDashboard({ onLoggedOut }) {
  const [stats, setStats] = useState(EMPTY_STATS);
  const [analytics, setAnalytics] = useState({ monthly: [], yearly: [] });
  const [filters, setFilters] = useState(EMPTY_FILTERS);
  const [draftFilters, setDraftFilters] = useState(EMPTY_FILTERS);
  const [requests, setRequests] = useState([]);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ page: 1, page_size: 20, total: 0, total_pages: 1 });
  const [users, setUsers] = useState([]);
  const [userSearch, setUserSearch] = useState('');
  const [toast, setToast] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [analyticsLoading, setAnalyticsLoading] = useState(true);
  const [reloadTick, setReloadTick] = useState(0);
  const [actionLoading, setActionLoading] = useState({});
  const [confirmRevoke, setConfirmRevoke] = useState(null);
  const [createForm, setCreateForm] = useState({
    transaction_id: buildTxId(),
    user_id: '',
    user_email: '',
    requested_plan: 'plus',
    amount: '',
    payment_provider: 'manual',
    note: '',
  });
  const [broadcastForm, setBroadcastForm] = useState({
    title: '',
    body: '',
    type: 'system',
    target_plan: '',
  });

  useEffect(() => {
    let alive = true;

    async function loadRequests() {
      if (alive) {
        setIsLoading(true);
      }
      try {
        const params = new URLSearchParams({
          ...filters,
          page: String(page),
          page_size: '20',
        });
        const data = await apiRequest(`/admin/api/upgrade-requests?${params.toString()}`);
        if (!alive) {
          return;
        }
        setStats(data.stats || EMPTY_STATS);
        setRequests(data.requests || []);
        setPagination({
          page: data.page || 1,
          page_size: data.page_size || 20,
          total: data.total || 0,
          total_pages: data.total_pages || 1,
        });
      } catch (error) {
        showToast(error.message);
        if (error.message === 'Unauthorized') {
          onLoggedOut();
        }
      } finally {
        if (alive) {
          setIsLoading(false);
        }
      }
    }

    loadRequests();
    const interval = setInterval(loadRequests, 15000);
    return () => {
      alive = false;
      clearInterval(interval);
    };
  }, [filters, page, reloadTick, onLoggedOut]);

  useEffect(() => {
    let alive = true;
    async function loadAnalytics() {
      if (alive) {
        setAnalyticsLoading(true);
      }
      try {
        const data = await apiRequest('/admin/api/analytics/upgrade-requests');
        if (!alive) {
          return;
        }
        setAnalytics(data.analytics || { monthly: [], yearly: [] });
        setStats(data.stats || EMPTY_STATS);
      } catch (error) {
        showToast(error.message);
      } finally {
        if (alive) {
          setAnalyticsLoading(false);
        }
      }
    }

    loadAnalytics();
  }, [reloadTick]);

  useEffect(() => {
    if (!toast) {
      return undefined;
    }
    const timer = setTimeout(() => setToast(''), 2600);
    return () => clearTimeout(timer);
  }, [toast]);

  function showToast(message) {
    setToast(message);
  }

  const statCards = useMemo(
    () => [
      { label: 'Total requests', value: stats.total },
      { label: 'Paid waiting code', value: stats.paid_waiting_code },
      { label: 'Codes sent', value: stats.codes_sent },
      { label: 'Redeemed', value: stats.redeemed },
    ],
    [stats],
  );

  function updateCreateForm(key, value) {
    setCreateForm((current) => ({ ...current, [key]: value }));
  }

  function updateDraftFilters(key, value) {
    setDraftFilters((current) => ({ ...current, [key]: value }));
  }

  function updateBroadcastForm(key, value) {
    setBroadcastForm((current) => ({ ...current, [key]: value }));
  }

  async function handleSearchUsers() {
    if (!userSearch.trim()) {
      setUsers([]);
      return;
    }
    try {
      const data = await apiRequest(`/admin/api/users/search?q=${encodeURIComponent(userSearch.trim())}`);
      setUsers(data.users || []);
    } catch (error) {
      showToast(error.message);
    }
  }

  async function handleCreateTransaction() {
    try {
      await apiRequest('/admin/api/upgrade-requests/mock', {
        method: 'POST',
        body: JSON.stringify({
          ...createForm,
          amount: createForm.amount ? Number(createForm.amount) : 0,
        }),
      });
      setCreateForm((current) => ({
        ...current,
        transaction_id: buildTxId(),
        amount: '',
        note: '',
      }));
      showToast('Da tao giao dich moi');
      setReloadTick((current) => current + 1);
    } catch (error) {
      showToast(error.message);
    }
  }

  async function handleBroadcastNotification() {
    try {
      const data = await apiRequest('/admin/api/notifications/broadcast', {
        method: 'POST',
        body: JSON.stringify(broadcastForm),
      });
      showToast(`Da gui thong bao toi ${data.sent_count} user`);
      setBroadcastForm({
        title: '',
        body: '',
        type: 'system',
        target_plan: '',
      });
    } catch (error) {
      showToast(error.message);
    }
  }

  async function runAction(id, action) {
    const endpointMap = {
      issue: `/admin/api/upgrade-requests/${id}/issue-code`,
      resend: `/admin/api/upgrade-requests/${id}/resend-code`,
      revoke: `/admin/api/upgrade-requests/${id}/revoke-code`,
    };

    setActionLoading((current) => ({ ...current, [`${action}:${id}`]: true }));
    try {
      const data = await apiRequest(endpointMap[action], {
        method: 'POST',
        body: JSON.stringify({ approved_by: 'admin-react-web' }),
      });
      showToast(data.message || 'Xu ly thanh cong');
      setReloadTick((current) => current + 1);
    } catch (error) {
      showToast(error.message);
    } finally {
      setActionLoading((current) => ({ ...current, [`${action}:${id}`]: false }));
    }
  }

  async function handleLogout() {
    try {
      await apiRequest('/admin/api/auth/logout', { method: 'POST' });
    } catch (_) {
      // ignore
    } finally {
      clearAuth();
      onLoggedOut();
    }
  }

  function handleApplyFilters() {
    setPage(1);
    setFilters({ ...draftFilters });
  }

  function handleClearFilters() {
    const reset = { ...EMPTY_FILTERS };
    setDraftFilters(reset);
    setFilters(reset);
    setPage(1);
    setReloadTick((current) => current + 1);
    showToast('Da xoa bo loc');
  }

  function handleRefresh() {
    setReloadTick((current) => current + 1);
    showToast('Da lam moi dashboard');
  }

  function handleResetCreateForm() {
    setCreateForm({
      transaction_id: buildTxId(),
      user_id: '',
      user_email: '',
      requested_plan: 'plus',
      amount: '',
      payment_provider: 'manual',
      note: '',
    });
    showToast('Da xoa form giao dich');
  }

  function handleClearUserSearch() {
    setUserSearch('');
    setUsers([]);
    showToast('Da xoa ket qua tim user');
  }

  function handleResetBroadcastForm() {
    setBroadcastForm({
      title: '',
      body: '',
      type: 'system',
      target_plan: '',
    });
    showToast('Da xoa form thong bao');
  }

  return (
    <div className="container">
      <div className="glass">
        <div className="hero">
          <div>
            <div className="badge">MeetingMind Admin React</div>
            <h1 className="page-title">Upgrade Operations Dashboard</h1>
            <p className="muted">
              Theo doi VNPAY, tim user, issue/resend/revoke code, va xem xu huong
              giao dich theo thang hoac nam.
            </p>
          </div>
          <div className="hero-actions">
            <button className="secondary" onClick={handleRefresh}>Refresh</button>
            <button className="ghost" onClick={handleLogout}>Dang xuat</button>
          </div>
        </div>

        <div className="stats">
          {statCards.map((card) => (
            <div className="stat" key={card.label}>
              <span>{card.label}</span>
              <strong>{card.value}</strong>
            </div>
          ))}
        </div>

        <div className="section">
          <div className="section-head">
            <div>
              <h2>Phan tich giao dich</h2>
              <div className="subtle">Bieu do request, paid va doanh thu theo thang / nam.</div>
            </div>
          </div>
          {analyticsLoading ? (
            <div className="subtle">Dang tai du lieu phan tich...</div>
          ) : (
            <div className="analytics-grid">
              <MiniBarChart
                title="Monthly Requests"
                subtitle="Tong so yeu cau nang cap theo thang"
                rows={analytics.monthly}
                valueKey="requests"
                colorClass="chart-blue"
              />
              <MiniBarChart
                title="Monthly Revenue"
                subtitle="Doanh thu da thanh toan theo thang"
                rows={analytics.monthly}
                valueKey="revenue"
                colorClass="chart-green"
              />
              <MiniBarChart
                title="Yearly Requests"
                subtitle="Tong so giao dich theo nam"
                rows={analytics.yearly}
                valueKey="requests"
                colorClass="chart-gold"
              />
              <MiniBarChart
                title="Yearly Paid"
                subtitle="So giao dich thanh cong theo nam"
                rows={analytics.yearly}
                valueKey="paid"
                colorClass="chart-red"
              />
            </div>
          )}
        </div>

        <div className="section">
          <div className="section-head">
            <div>
              <h2>Broadcast notification</h2>
              <div className="subtle">
                Gui thong bao cap nhat he thong den tat ca user hoac theo tung goi.
              </div>
            </div>
          </div>
          <div className="grid grid-broadcast">
            <input
              value={broadcastForm.title}
              onChange={(event) => updateBroadcastForm('title', event.target.value)}
              placeholder="Tieu de thong bao"
            />
            <select
              value={broadcastForm.type}
              onChange={(event) => updateBroadcastForm('type', event.target.value)}
            >
              <option value="system">system</option>
              <option value="announcement">announcement</option>
              <option value="update">update</option>
            </select>
            <select
              value={broadcastForm.target_plan}
              onChange={(event) => updateBroadcastForm('target_plan', event.target.value)}
            >
              <option value="">Tat ca user</option>
              <option value="free">free</option>
              <option value="plus">plus</option>
              <option value="premium">premium</option>
            </select>
          </div>
          <div className="top-space">
            <textarea
              value={broadcastForm.body}
              onChange={(event) => updateBroadcastForm('body', event.target.value)}
              placeholder="Noi dung thong bao, vi du: He thong se bao tri luc 23:00 toi nay."
            />
          </div>
          <div className="hero-actions top-space">
            <button className="narrow" onClick={handleBroadcastNotification}>
              Gui thong bao
            </button>
            <button className="ghost narrow" onClick={handleResetBroadcastForm}>
              Clear form
            </button>
          </div>
        </div>

        <div className="section">
          <div className="section-head">
            <div>
              <h2>Tim user nhanh</h2>
              <div className="subtle">Tim theo id, email hoac ten roi dien vao giao dich.</div>
            </div>
          </div>
          <div className="toolbar user-toolbar">
            <input value={userSearch} onChange={(event) => setUserSearch(event.target.value)} placeholder="Nhap user id, email hoac ten" />
            <button className="secondary" onClick={handleSearchUsers}>Tim user</button>
            <button className="ghost" onClick={handleClearUserSearch}>Clear user</button>
          </div>
          <div className="stack-md top-space">
            {users.map((user) => (
              <div className="user-card" key={user.id}>
                <div>
                  <strong>{user.name || 'Unknown user'}</strong>
                  <div className="subtle">{user.email || ''}</div>
                  <div className="subtle">{user.id} ? plan {user.plan}</div>
                </div>
                <button
                  className="secondary narrow"
                  onClick={() =>
                    setCreateForm((current) => ({
                      ...current,
                      user_id: user.id,
                      user_email: user.email || '',
                    }))
                  }
                >
                  Dung user nay
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="section">
          <div className="section-head">
            <div>
              <h2>Manual transaction</h2>
              <div className="subtle">Fallback cho test va giao dich ngoai VNPAY.</div>
            </div>
          </div>
          <div className="grid">
            <input value={createForm.transaction_id} onChange={(event) => updateCreateForm('transaction_id', event.target.value)} placeholder="Transaction ID" />
            <input value={createForm.user_id} onChange={(event) => updateCreateForm('user_id', event.target.value)} placeholder="User ID" />
            <input value={createForm.user_email} onChange={(event) => updateCreateForm('user_email', event.target.value)} placeholder="User email" />
            <select value={createForm.requested_plan} onChange={(event) => updateCreateForm('requested_plan', event.target.value)}>
              <option value="plus">plus</option>
              <option value="premium">premium</option>
            </select>
            <input value={createForm.amount} onChange={(event) => updateCreateForm('amount', event.target.value)} type="number" placeholder="Amount" />
            <input value={createForm.payment_provider} onChange={(event) => updateCreateForm('payment_provider', event.target.value)} placeholder="Provider" />
          </div>
          <div className="top-space">
            <textarea value={createForm.note} onChange={(event) => updateCreateForm('note', event.target.value)} placeholder="Ghi chu giao dich" />
          </div>
          <div className="hero-actions top-space">
            <button className="narrow" onClick={handleCreateTransaction}>Tao giao dich</button>
            <button className="secondary narrow" onClick={() => updateCreateForm('transaction_id', buildTxId())}>Tao ma moi</button>
            <button className="ghost narrow" onClick={handleResetCreateForm}>Clear form</button>
          </div>
        </div>

        <div className="section">
          <div className="section-head">
            <div>
              <h2>Upgrade queue</h2>
              <div className="subtle">Loc theo plan, code status va payment status.</div>
            </div>
          </div>

          <div className="toolbar">
            <input value={draftFilters.search} onChange={(event) => updateDraftFilters('search', event.target.value)} placeholder="Search transaction, user, email, code" />
            <select value={draftFilters.plan} onChange={(event) => updateDraftFilters('plan', event.target.value)}>
              <option value="">All plans</option>
              <option value="plus">plus</option>
              <option value="premium">premium</option>
            </select>
            <select value={draftFilters.status} onChange={(event) => updateDraftFilters('status', event.target.value)}>
              <option value="">All code statuses</option>
              <option value="pending">pending</option>
              <option value="code_sent">code_sent</option>
              <option value="redeemed">redeemed</option>
              <option value="revoked">revoked</option>
              <option value="failed">failed</option>
            </select>
            <select value={draftFilters.payment_status} onChange={(event) => updateDraftFilters('payment_status', event.target.value)}>
              <option value="">All payment statuses</option>
              <option value="created">created</option>
              <option value="pending">pending</option>
              <option value="paid">paid</option>
              <option value="failed">failed</option>
              <option value="cancelled">cancelled</option>
            </select>
            <button className="secondary" onClick={handleApplyFilters}>Apply</button>
            <button className="ghost" onClick={handleClearFilters}>Clear</button>
          </div>

          <div className="table-wrap top-space">
            <table>
              <thead>
                <tr>
                  <th>Transaction</th>
                  <th>User</th>
                  <th>Plan</th>
                  <th>Payment</th>
                  <th>Code State</th>
                  <th>Timestamps</th>
                  <th>Code</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan="8">Dang tai du lieu...</td>
                  </tr>
                ) : requests.length ? (
                  requests.map((item) => {
                    const issueDisabled =
                      item.status === 'code_sent' ||
                      item.status === 'redeemed' ||
                      (item.payment_provider === 'vnpay' && item.payment_status !== 'paid');
                    const resendDisabled = !item.issued_code || item.status === 'revoked';
                    const revokeDisabled = !item.issued_code || item.status === 'revoked';
                    return (
                      <tr key={item.id}>
                        <td>
                          <strong>{item.transaction_id}</strong>
                          <div className="subtle">{item.payment_provider || '-'} ? {item.created_at || ''}</div>
                        </td>
                        <td>
                          <div>{item.user_id}</div>
                          <div className="subtle">{item.user_email || ''}</div>
                        </td>
                        <td>
                          <strong>{item.requested_plan}</strong>
                        </td>
                        <td>
                          <StatusBadge value={item.payment_status} />
                          <div className="subtle">VNPAY code: {item.vnp_response_code || '-'}</div>
                        </td>
                        <td><StatusBadge value={item.status} /></td>
                        <td>
                          <div className="subtle">paid: {item.paid_at || '-'}</div>
                          <div className="subtle">approved: {item.approved_at || '-'}</div>
                        </td>
                        <td>
                          <strong>{item.issued_code || '-'}</strong>
                          <div className="subtle">{item.amount || '-'} {item.currency || ''}</div>
                        </td>
                        <td>
                          <div className="actions">
                            <button disabled={issueDisabled || actionLoading[`issue:${item.id}`]} onClick={() => runAction(item.id, 'issue')}>
                              {actionLoading[`issue:${item.id}`] ? '...' : 'Issue'}
                            </button>
                            <button className="secondary" disabled={resendDisabled || actionLoading[`resend:${item.id}`]} onClick={() => runAction(item.id, 'resend')}>
                              {actionLoading[`resend:${item.id}`] ? '...' : 'Resend'}
                            </button>
                            <button className="ghost" disabled={revokeDisabled || actionLoading[`revoke:${item.id}`]} onClick={() => setConfirmRevoke(item)}>
                              Revoke
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan="8">Khong co giao dich phu hop.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="pagination-row top-space">
            <div className="subtle">
              Trang {pagination.page} / {pagination.total_pages} • Tong {pagination.total} giao dich
            </div>
            <div className="hero-actions">
              <button className="ghost narrow" disabled={pagination.page <= 1} onClick={() => setPage((current) => Math.max(current - 1, 1))}>
                Prev
              </button>
              <button className="secondary narrow" disabled={pagination.page >= pagination.total_pages} onClick={() => setPage((current) => Math.min(current + 1, pagination.total_pages))}>
                Next
              </button>
            </div>
          </div>
        </div>
      </div>

      <ConfirmDialog
        open={Boolean(confirmRevoke)}
        title="Revoke code?"
        description={
          confirmRevoke
            ? `Ban sap thu hoi code ${confirmRevoke.issued_code || '-'} cua giao dich ${confirmRevoke.transaction_id}.`
            : ''
        }
        confirmLabel="Xac nhan revoke"
        loading={Boolean(confirmRevoke && actionLoading[`revoke:${confirmRevoke.id}`])}
        onCancel={() => setConfirmRevoke(null)}
        onConfirm={async () => {
          if (!confirmRevoke) {
            return;
          }
          await runAction(confirmRevoke.id, 'revoke');
          setConfirmRevoke(null);
        }}
      />

      <div className={`toast ${toast ? 'show' : ''}`}>{toast}</div>
    </div>
  );
}
