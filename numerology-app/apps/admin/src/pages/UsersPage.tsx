import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, EmptyState, ErrorState, Loading, Pagination, Toast } from '../components/ui';

interface UserRow {
  id: string;
  email: string | null;
  isGuest: boolean;
  status: 'ACTIVE' | 'DISABLED';
  provider: string;
  lastLoginAt: string | null;
  createdAt: string;
  profile: { displayName: string | null; mulank: number | null; bhagyank: number | null } | null;
  _count: { history: number };
}

interface UserDetail extends UserRow {
  preferences: { locale: string; theme: string; analyticsConsent: boolean } | null;
  history: Array<{ id: string; type: string; label: string; createdAt: string }>;
}

export function UsersPage({ canWrite, canDelete }: { canWrite: boolean; canDelete: boolean }) {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [type, setType] = useState('');
  const [selected, setSelected] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const list = useAsync(
    async () =>
      api<UserRow[]>('/admin/users', {
        query: { page, pageSize: 20, search: search || undefined, status: status || undefined, type: type || undefined },
      }),
    [page, search, status, type],
  );

  const detail = useAsync(
    async () => (selected ? (await api<UserDetail>(`/admin/users/${selected}`)).data : null),
    [selected],
  );

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const setStatusFor = async (id: string, next: 'ACTIVE' | 'DISABLED') => {
    try {
      await api(`/admin/users/${id}/status`, { method: 'PATCH', body: { status: next } });
      setToast({ message: next === 'DISABLED' ? 'User disabled.' : 'User enabled.', tone: 'info' });
      await list.reload();
      if (selected === id) await detail.reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    }
  };

  const remove = async (id: string) => {
    if (!window.confirm('Delete this user? Their profile, history and saved results are removed permanently.')) return;
    try {
      await api(`/admin/users/${id}`, { method: 'DELETE' });
      setToast({ message: 'User deleted.', tone: 'info' });
      setSelected(null);
      await list.reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    }
  };

  if (list.loading) return <Loading rows={8} label="Loading users…" />;
  if (list.error) return <ErrorState message={list.error} onRetry={list.reload} />;

  const rows = list.data?.data ?? [];
  const meta = list.data?.meta;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Users</h1>
        <p className="muted">Accounts and guest sessions. Passwords are never shown or exported.</p>
      </header>

      <Card
        action={
          <div className="btn-row">
            <input
              placeholder="Search by email or name…"
              aria-label="Search users"
              value={search}
              onChange={(event) => {
                setPage(1);
                setSearch(event.target.value);
              }}
              style={{ width: 220 }}
            />
            <select
              aria-label="Status filter"
              value={status}
              onChange={(event) => {
                setPage(1);
                setStatus(event.target.value);
              }}
              style={{ width: 150 }}
            >
              <option value="">All statuses</option>
              <option value="ACTIVE">Active</option>
              <option value="DISABLED">Disabled</option>
            </select>
            <select
              aria-label="Account type filter"
              value={type}
              onChange={(event) => {
                setPage(1);
                setType(event.target.value);
              }}
              style={{ width: 150 }}
            >
              <option value="">All accounts</option>
              <option value="ACCOUNT">Registered</option>
              <option value="GUEST">Guest</option>
            </select>
          </div>
        }
      >
        {rows.length === 0 ? (
          <EmptyState title="No users found" description="Try a different search or filter." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>User</th>
                  <th>Numbers</th>
                  <th>Calculations</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div>{user.profile?.displayName ?? (user.isGuest ? 'Guest' : '—')}</div>
                      <div className="muted mono">{user.email ?? 'no email'}</div>
                    </td>
                    <td>
                      {user.profile?.mulank ? (
                        <>
                          <span className="badge">M {user.profile.mulank}</span>{' '}
                          <span className="badge gold">B {user.profile.bhagyank}</span>
                        </>
                      ) : (
                        <span className="muted">no date of birth</span>
                      )}
                    </td>
                    <td>{user._count.history}</td>
                    <td>
                      <span className={`badge ${user.status === 'ACTIVE' ? 'success' : 'danger'}`}>
                        {user.status === 'ACTIVE' ? 'Active' : 'Disabled'}
                      </span>
                      {user.isGuest && <span className="badge muted" style={{ marginLeft: 6 }}>Guest</span>}
                    </td>
                    <td className="muted">{new Date(user.createdAt).toLocaleDateString()}</td>
                    <td className="actions">
                      <div className="btn-row" style={{ justifyContent: 'flex-end' }}>
                        <button type="button" className="btn-secondary" onClick={() => setSelected(user.id)}>
                          View
                        </button>
                        {canWrite && (
                          <button
                            type="button"
                            className="btn-secondary"
                            onClick={() => setStatusFor(user.id, user.status === 'ACTIVE' ? 'DISABLED' : 'ACTIVE')}
                          >
                            {user.status === 'ACTIVE' ? 'Disable' : 'Enable'}
                          </button>
                        )}
                        {canDelete && (
                          <button type="button" className="btn-danger" onClick={() => remove(user.id)}>
                            Delete
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {meta && <Pagination page={meta.page} totalPages={meta.totalPages} total={meta.total} onChange={setPage} />}
      </Card>

      {selected && (
        <Card
          title="User detail"
          action={
            <button type="button" className="btn-secondary" onClick={() => setSelected(null)}>
              Close
            </button>
          }
        >
          {detail.loading ? (
            <Loading rows={4} />
          ) : detail.error ? (
            <ErrorState message={detail.error} onRetry={detail.reload} />
          ) : detail.data ? (
            <>
              <div className="field-row">
                <div>
                  <label>Name</label>
                  <div>{detail.data.profile?.displayName ?? '—'}</div>
                </div>
                <div>
                  <label>Email</label>
                  <div className="mono">{detail.data.email ?? 'no email'}</div>
                </div>
                <div>
                  <label>Language</label>
                  <div>{detail.data.preferences?.locale ?? 'en'}</div>
                </div>
                <div>
                  <label>Analytics consent</label>
                  <div>{detail.data.preferences?.analyticsConsent ? 'Given' : 'Not given'}</div>
                </div>
              </div>

              <h3 style={{ marginTop: 12 }}>Recent activity</h3>
              {detail.data.history.length === 0 ? (
                <p className="muted">No calculations yet.</p>
              ) : (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>Type</th>
                        <th>Input</th>
                        <th>When</th>
                      </tr>
                    </thead>
                    <tbody>
                      {detail.data.history.map((entry) => (
                        <tr key={entry.id}>
                          <td>{entry.type.replace(/_/g, ' ').toLowerCase()}</td>
                          <td className="mono">{entry.label}</td>
                          <td className="muted">{new Date(entry.createdAt).toLocaleString()}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </>
          ) : null}
        </Card>
      )}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
