import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, Toast } from '../components/ui';

interface Setting {
  id: string;
  key: string;
  value: unknown;
  group: string;
  description: string | null;
  isPublic: boolean;
}

/**
 * App settings editor. Values are JSON so the same screen can manage simple
 * values, feature switches and localised text without a bespoke form per key.
 */
export function SettingsPage({ canWrite }: { canWrite: boolean }) {
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(async () => (await api<Setting[]>('/admin/settings')).data, []);

  useEffect(() => {
    if (data) {
      setDrafts(Object.fromEntries(data.map((setting) => [setting.key, JSON.stringify(setting.value, null, 2)])));
    }
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const save = async (key: string) => {
    const raw = drafts[key] ?? '';
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      setToast({ message: `${key}: this is not valid JSON.`, tone: 'error' });
      return;
    }

    setSavingKey(key);
    try {
      await api(`/admin/settings/${encodeURIComponent(key)}`, { method: 'PUT', body: { value: parsed } });
      setToast({ message: `${key} saved.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSavingKey(null);
    }
  };

  if (loading) return <Loading rows={8} label="Loading settings…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  const groups = [...new Set((data ?? []).map((setting) => setting.group))];

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>App settings</h1>
        <p className="muted">
          Branding, feature switches, maintenance mode and content shown in the app. Public settings are sent to the
          app; private ones stay on the server.
        </p>
      </header>

      {groups.map((group) => (
        <Card key={group} title={group.charAt(0).toUpperCase() + group.slice(1)}>
          {(data ?? [])
            .filter((setting) => setting.group === group)
            .map((setting) => (
              <div key={setting.key} className="field" style={{ borderTop: '1px solid var(--border)', paddingTop: 14 }}>
                <label htmlFor={`setting-${setting.key}`}>
                  {setting.key} {setting.isPublic ? <span className="badge muted">public</span> : <span className="badge">private</span>}
                </label>
                {setting.description && <div className="hint" style={{ marginBottom: 6 }}>{setting.description}</div>}
                <textarea
                  id={`setting-${setting.key}`}
                  className="mono"
                  disabled={!canWrite}
                  value={drafts[setting.key] ?? ''}
                  onChange={(event) => setDrafts((current) => ({ ...current, [setting.key]: event.target.value }))}
                  rows={Math.min(14, (drafts[setting.key] ?? '').split('\n').length + 1)}
                />
                {canWrite && (
                  <div className="btn-row" style={{ marginTop: 8 }}>
                    <button
                      type="button"
                      className="btn-primary"
                      onClick={() => save(setting.key)}
                      disabled={savingKey === setting.key}
                    >
                      {savingKey === setting.key ? 'Saving…' : 'Save'}
                    </button>
                  </div>
                )}
              </div>
            ))}
        </Card>
      ))}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
