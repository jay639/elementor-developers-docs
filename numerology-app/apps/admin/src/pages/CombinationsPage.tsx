import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, ListField, Loading, LocaleTabs, Pagination, Toast } from '../components/ui';

interface Combination {
  id: string;
  mulank: number;
  bhagyank: number;
  locale: string;
  title: string;
  description: string;
  personality: string;
  strengths: string[];
  challenges: string[];
  career: string;
  relationships: string;
  recommendations: string;
  isPublished: boolean;
}

/** Manages all 81 Mulank x Bhagyank combinations, per language. */
export function CombinationsPage({ canWrite }: { canWrite: boolean }) {
  const [locale, setLocale] = useState('en');
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [editing, setEditing] = useState<Combination | null>(null);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(async () => {
    const response = await api<Combination[]>('/admin/numerology/combinations', {
      query: { locale, page, pageSize: 20, search: search || undefined },
    });
    return response;
  }, [locale, page, search]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const save = async () => {
    if (!editing) return;
    setSaving(true);
    try {
      const { id, mulank, bhagyank, locale: rowLocale, ...payload } = editing;
      void id;
      void rowLocale;
      await api(`/admin/numerology/combinations/${mulank}/${bhagyank}/${locale}`, { method: 'PUT', body: payload });
      setToast({ message: `Combination ${mulank} + ${bhagyank} saved.`, tone: 'info' });
      setEditing(null);
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Loading rows={8} label="Loading combinations…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  const rows = data?.data ?? [];
  const meta = data?.meta;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Mulank + Bhagyank combinations</h1>
        <p className="muted">
          All 81 combinations for each language. When a combination is missing or unpublished the app falls back to the
          two individual number interpretations.
        </p>
      </header>

      {editing ? (
        <Card
          title={`Mulank ${editing.mulank} + Bhagyank ${editing.bhagyank}`}
          action={
            <div className="btn-row">
              <button type="button" className="btn-secondary" onClick={() => setEditing(null)}>
                Cancel
              </button>
              {canWrite && (
                <button type="button" className="btn-primary" onClick={save} disabled={saving}>
                  {saving ? 'Saving…' : 'Save changes'}
                </button>
              )}
            </div>
          }
        >
          <fieldset disabled={!canWrite} style={{ border: 0, padding: 0, margin: 0 }}>
            <div className="field">
              <label htmlFor="c-title">Title</label>
              <input
                id="c-title"
                value={editing.title}
                onChange={(event) => setEditing({ ...editing, title: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="c-description">Description</label>
              <textarea
                id="c-description"
                value={editing.description}
                onChange={(event) => setEditing({ ...editing, description: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="c-personality">Personality</label>
              <textarea
                id="c-personality"
                value={editing.personality}
                onChange={(event) => setEditing({ ...editing, personality: event.target.value })}
              />
            </div>
            <ListField
              label="Strengths"
              value={editing.strengths}
              onChange={(value) => setEditing({ ...editing, strengths: value })}
            />
            <ListField
              label="Challenges"
              value={editing.challenges}
              onChange={(value) => setEditing({ ...editing, challenges: value })}
            />
            <div className="field">
              <label htmlFor="c-career">Career</label>
              <textarea
                id="c-career"
                value={editing.career}
                onChange={(event) => setEditing({ ...editing, career: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="c-relationships">Relationships</label>
              <textarea
                id="c-relationships"
                value={editing.relationships}
                onChange={(event) => setEditing({ ...editing, relationships: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="c-recommendations">Recommendations</label>
              <textarea
                id="c-recommendations"
                value={editing.recommendations}
                onChange={(event) => setEditing({ ...editing, recommendations: event.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="c-published">
                <input
                  id="c-published"
                  type="checkbox"
                  style={{ width: 'auto', marginRight: 8, minHeight: 'auto' }}
                  checked={editing.isPublished}
                  onChange={(event) => setEditing({ ...editing, isPublished: event.target.checked })}
                />
                Published
              </label>
            </div>
          </fieldset>
        </Card>
      ) : (
        <Card
          action={
            <div className="btn-row">
              <input
                placeholder="Search combinations…"
                aria-label="Search combinations"
                value={search}
                onChange={(event) => {
                  setPage(1);
                  setSearch(event.target.value);
                }}
                style={{ width: 240 }}
              />
              <LocaleTabs
                value={locale}
                onChange={(next) => {
                  setPage(1);
                  setLocale(next);
                }}
              />
            </div>
          }
        >
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Mulank</th>
                  <th>Bhagyank</th>
                  <th>Title</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <span className="number-chip on" aria-hidden="true">
                        {row.mulank}
                      </span>
                    </td>
                    <td>
                      <span className="number-chip" aria-hidden="true">
                        {row.bhagyank}
                      </span>
                    </td>
                    <td>{row.title}</td>
                    <td>
                      <span className={`badge ${row.isPublished ? 'success' : 'muted'}`}>
                        {row.isPublished ? 'Published' : 'Draft'}
                      </span>
                    </td>
                    <td className="actions">
                      <button type="button" className="btn-secondary" onClick={() => setEditing({ ...row })}>
                        {canWrite ? 'Edit' : 'View'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {meta && (
            <Pagination page={meta.page} totalPages={meta.totalPages} total={meta.total} onChange={setPage} />
          )}
        </Card>
      )}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
