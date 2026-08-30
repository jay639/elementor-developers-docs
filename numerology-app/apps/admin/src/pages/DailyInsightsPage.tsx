import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, LocaleTabs, Toast } from '../components/ui';

interface Insight {
  id: string;
  number: number;
  locale: string;
  title: string;
  message: string;
}

/** Copy shown under Today's Lucky Number on the home screen. */
export function DailyInsightsPage({ canWrite }: { canWrite: boolean }) {
  const [locale, setLocale] = useState('en');
  const [drafts, setDrafts] = useState<Record<number, Insight>>({});
  const [savingNumber, setSavingNumber] = useState<number | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<Insight[]>('/admin/numerology/daily-insights', { query: { locale } })).data,
    [locale],
  );

  useEffect(() => {
    if (data) setDrafts(Object.fromEntries(data.map((row) => [row.number, { ...row }])));
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const save = async (number: number) => {
    const row = drafts[number];
    if (!row) return;
    setSavingNumber(number);
    try {
      await api(`/admin/numerology/daily-insights/${number}/${locale}`, {
        method: 'PUT',
        body: { title: row.title, message: row.message },
      });
      setToast({ message: `Insight for number ${number} saved.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSavingNumber(null);
    }
  };

  if (loading) return <Loading rows={6} label="Loading daily insights…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Today&apos;s number</h1>
        <p className="muted">
          The number itself is calculated from the current date and changes every day on its own. This screen manages
          the short interpretation shown beneath it.
        </p>
      </header>

      <Card action={<LocaleTabs value={locale} onChange={setLocale} />}>
        {Object.values(drafts)
          .sort((a, b) => a.number - b.number)
          .map((row) => (
            <div key={row.id} className="field" style={{ borderTop: '1px solid var(--border)', paddingTop: 14 }}>
              <div className="btn-row" style={{ marginBottom: 8 }}>
                <span className="number-chip on" aria-hidden="true">
                  {row.number}
                </span>
                <input
                  aria-label={`Title for number ${row.number}`}
                  disabled={!canWrite}
                  value={row.title}
                  onChange={(event) =>
                    setDrafts((current) => ({ ...current, [row.number]: { ...row, title: event.target.value } }))
                  }
                  style={{ flex: 1, minWidth: 200 }}
                />
              </div>
              <textarea
                aria-label={`Message for number ${row.number}`}
                disabled={!canWrite}
                value={row.message}
                onChange={(event) =>
                  setDrafts((current) => ({ ...current, [row.number]: { ...row, message: event.target.value } }))
                }
              />
              {canWrite && (
                <div className="btn-row" style={{ marginTop: 8 }}>
                  <button
                    type="button"
                    className="btn-primary"
                    onClick={() => save(row.number)}
                    disabled={savingNumber === row.number}
                  >
                    {savingNumber === row.number ? 'Saving…' : 'Save'}
                  </button>
                </div>
              )}
            </div>
          ))}
      </Card>

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
