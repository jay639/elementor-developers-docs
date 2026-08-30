import { useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, EmptyState, ErrorState, Loading, Pagination } from '../components/ui';

interface AuditRow {
  id: string;
  action: string;
  entityType: string;
  entityId: string | null;
  createdAt: string;
  ip: string | null;
  before: unknown;
  after: unknown;
  admin: { id: string; name: string; email: string } | null;
}

/** Read-only trail of every sensitive administrator action. */
export function AuditLogPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [expanded, setExpanded] = useState<string | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => api<AuditRow[]>('/admin/audit-logs', { query: { page, pageSize: 20, search: search || undefined } }),
    [page, search],
  );

  if (loading) return <Loading rows={8} label="Loading audit log…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  const rows = data?.data ?? [];
  const meta = data?.meta;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Audit log</h1>
        <p className="muted">Administrator logins, content edits, rule changes and user actions.</p>
      </header>

      <Card
        action={
          <input
            placeholder="Search actions…"
            aria-label="Search audit log"
            value={search}
            onChange={(event) => {
              setPage(1);
              setSearch(event.target.value);
            }}
            style={{ width: 240 }}
          />
        }
      >
        {rows.length === 0 ? (
          <EmptyState title="Nothing recorded yet" description="Administrator actions will appear here." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>When</th>
                  <th>Administrator</th>
                  <th>Action</th>
                  <th>Record</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td className="muted">{new Date(row.createdAt).toLocaleString()}</td>
                    <td>
                      <div>{row.admin?.name ?? 'System'}</div>
                      <div className="muted mono">{row.admin?.email ?? '—'}</div>
                    </td>
                    <td className="mono">{row.action}</td>
                    <td>
                      <div>{row.entityType}</div>
                      <div className="muted mono">{row.entityId?.slice(0, 8) ?? '—'}</div>
                    </td>
                    <td className="actions">
                      {Boolean(row.before ?? row.after) && (
                        <button
                          type="button"
                          className="btn-secondary"
                          onClick={() => setExpanded(expanded === row.id ? null : row.id)}
                        >
                          {expanded === row.id ? 'Hide' : 'Changes'}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {expanded && (
          <div className="grid two" style={{ marginTop: 14 }}>
            <div>
              <h3>Before</h3>
              <pre className="mono" style={{ overflowX: 'auto', background: '#fafaf8', padding: 12, borderRadius: 10 }}>
                {JSON.stringify(rows.find((row) => row.id === expanded)?.before ?? null, null, 2)}
              </pre>
            </div>
            <div>
              <h3>After</h3>
              <pre className="mono" style={{ overflowX: 'auto', background: '#fafaf8', padding: 12, borderRadius: 10 }}>
                {JSON.stringify(rows.find((row) => row.id === expanded)?.after ?? null, null, 2)}
              </pre>
            </div>
          </div>
        )}

        {meta && <Pagination page={meta.page} totalPages={meta.totalPages} total={meta.total} onChange={setPage} />}
      </Card>
    </>
  );
}
