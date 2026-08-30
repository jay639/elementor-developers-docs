import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, LocaleTabs, Toast } from '../components/ui';

interface LegalDocument {
  id: string;
  type: 'TERMS' | 'PRIVACY' | 'DISCLAIMER' | 'ABOUT';
  locale: string;
  title: string;
  body: string;
  version: string;
}

const LABELS: Record<string, string> = {
  TERMS: 'Terms & Conditions',
  PRIVACY: 'Privacy Policy',
  DISCLAIMER: 'Disclaimer',
  ABOUT: 'About',
};

export function LegalPage({ canWrite }: { canWrite: boolean }) {
  const [locale, setLocale] = useState('en');
  const [drafts, setDrafts] = useState<Record<string, LegalDocument>>({});
  const [savingType, setSavingType] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<LegalDocument[]>('/admin/numerology/legal', { query: { locale } })).data,
    [locale],
  );

  useEffect(() => {
    if (data) setDrafts(Object.fromEntries(data.map((row) => [row.type, { ...row }])));
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const save = async (type: string) => {
    const row = drafts[type];
    if (!row) return;
    setSavingType(type);
    try {
      await api(`/admin/numerology/legal/${type}/${locale}`, {
        method: 'PUT',
        body: { title: row.title, body: row.body, version: row.version },
      });
      setToast({ message: `${LABELS[type]} saved.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSavingType(null);
    }
  };

  if (loading) return <Loading rows={6} label="Loading legal documents…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Legal documents</h1>
        <p className="muted">
          Terms, privacy policy, disclaimer and about text, shown in the app in the user&apos;s language.
        </p>
      </header>

      <Card action={<LocaleTabs value={locale} onChange={setLocale} />}>
        {Object.values(drafts).map((row) => (
          <div key={row.id} className="field" style={{ borderTop: '1px solid var(--border)', paddingTop: 14 }}>
            <label htmlFor={`legal-${row.type}`}>{LABELS[row.type] ?? row.type}</label>
            <input
              aria-label={`${LABELS[row.type]} title`}
              disabled={!canWrite}
              value={row.title}
              onChange={(event) => setDrafts((current) => ({ ...current, [row.type]: { ...row, title: event.target.value } }))}
              style={{ marginBottom: 8 }}
            />
            <textarea
              id={`legal-${row.type}`}
              disabled={!canWrite}
              rows={10}
              value={row.body}
              onChange={(event) => setDrafts((current) => ({ ...current, [row.type]: { ...row, body: event.target.value } }))}
            />
            {canWrite && (
              <div className="btn-row" style={{ marginTop: 8 }}>
                <input
                  aria-label="Version"
                  value={row.version}
                  onChange={(event) =>
                    setDrafts((current) => ({ ...current, [row.type]: { ...row, version: event.target.value } }))
                  }
                  style={{ width: 100 }}
                />
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => save(row.type)}
                  disabled={savingType === row.type}
                >
                  {savingType === row.type ? 'Saving…' : 'Save'}
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
