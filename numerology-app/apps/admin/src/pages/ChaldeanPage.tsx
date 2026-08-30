import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, Toast } from '../components/ui';

interface ChaldeanResponse {
  groups: Record<string, string[]>;
  letters: Array<{ id: string; letter: string; value: number }>;
}

const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

/** Chaldean letter values. Traditionally no letter is assigned to 9. */
export function ChaldeanPage({ canWrite }: { canWrite: boolean }) {
  const [groups, setGroups] = useState<Record<string, string[]>>({});
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<ChaldeanResponse>('/admin/chaldean-mappings')).data,
    [],
  );

  useEffect(() => {
    if (data) setGroups(data.groups);
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const assign = (letter: string, value: string) => {
    setGroups((current) => {
      const next: Record<string, string[]> = {};
      for (const [key, letters] of Object.entries(current)) {
        next[key] = letters.filter((item) => item !== letter);
      }
      if (value !== '') {
        next[value] = [...(next[value] ?? []), letter].sort();
      }
      return next;
    });
  };

  const valueOf = (letter: string): string => {
    for (const [value, letters] of Object.entries(groups)) {
      if (letters.includes(letter)) return value;
    }
    return '';
  };

  const save = async () => {
    setSaving(true);
    try {
      await api('/admin/chaldean-mappings', { method: 'PUT', body: { groups } });
      setToast({ message: 'Chaldean mapping saved. Name calculations use it immediately.', tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Loading rows={6} label="Loading Chaldean mapping…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  const unmapped = ALPHABET.filter((letter) => valueOf(letter) === '');

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Chaldean mapping</h1>
        <p className="muted">
          The letter values used for name numerology. In the traditional Chaldean system no letter is assigned to 9;
          that is intentional, not a gap.
        </p>
      </header>

      <Card
        title="Current table"
        action={
          canWrite && (
            <button type="button" className="btn-primary" onClick={save} disabled={saving}>
              {saving ? 'Saving…' : 'Save mapping'}
            </button>
          )
        }
      >
        {unmapped.length > 0 && (
          <div className="alert warning">
            Not mapped yet: {unmapped.join(', ')}. Unmapped letters are ignored during a calculation.
          </div>
        )}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Value</th>
                <th>Letters</th>
              </tr>
            </thead>
            <tbody>
              {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((value) => (
                <tr key={value}>
                  <td>
                    <span className="number-chip on" aria-hidden="true">
                      {value}
                    </span>
                  </td>
                  <td>
                    {(groups[String(value)] ?? []).length === 0 ? (
                      <span className="muted">— no letters —</span>
                    ) : (
                      (groups[String(value)] ?? []).join('  ·  ')
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <Card title="Assign letters">
        <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))', gap: 12 }}>
          {ALPHABET.map((letter) => (
            <div key={letter} className="field" style={{ marginBottom: 0 }}>
              <label htmlFor={`letter-${letter}`}>{letter}</label>
              <select
                id={`letter-${letter}`}
                disabled={!canWrite}
                value={valueOf(letter)}
                onChange={(event) => assign(letter, event.target.value)}
              >
                <option value="">Not mapped</option>
                {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((value) => (
                  <option key={value} value={value}>
                    {value}
                  </option>
                ))}
              </select>
            </div>
          ))}
        </div>
      </Card>

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
