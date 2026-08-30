import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, NumberPicker, Toast } from '../components/ui';

interface MarriageRule {
  id: string;
  driverNumber: number;
  compatibleMulank: number[];
  compatibleBhagyank: number[];
  enabled: boolean;
  notes: Record<string, string>;
}

/**
 * Marriage compatibility rules.
 *
 * The engine runs this table in both directions - male -> female and
 * female -> male - so each row describes how that Mulank matches a partner,
 * whichever partner holds it.
 */
export function CompatibilityRulesPage({ canWrite }: { canWrite: boolean }) {
  const [drafts, setDrafts] = useState<Record<number, MarriageRule>>({});
  const [savingNumber, setSavingNumber] = useState<number | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<MarriageRule[]>('/admin/compatibility-rules')).data,
    [],
  );

  useEffect(() => {
    if (data) setDrafts(Object.fromEntries(data.map((rule) => [rule.driverNumber, { ...rule }])));
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const toggle = (driverNumber: number, field: 'compatibleMulank' | 'compatibleBhagyank', value: number) => {
    setDrafts((current) => {
      const rule = current[driverNumber];
      if (!rule) return current;
      const list = rule[field];
      return {
        ...current,
        [driverNumber]: {
          ...rule,
          [field]: list.includes(value)
            ? list.filter((item) => item !== value)
            : [...list, value].sort((a, b) => a - b),
        },
      };
    });
  };

  const save = async (driverNumber: number) => {
    const rule = drafts[driverNumber];
    if (!rule) return;
    setSavingNumber(driverNumber);
    try {
      await api(`/admin/compatibility-rules/${driverNumber}`, {
        method: 'PUT',
        body: {
          compatibleMulank: rule.compatibleMulank,
          compatibleBhagyank: rule.compatibleBhagyank,
          enabled: rule.enabled,
          notes: rule.notes ?? {},
        },
      });
      setToast({ message: `Rule for Mulank ${driverNumber} saved.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSavingNumber(null);
    }
  };

  if (loading) return <Loading rows={9} label="Loading compatibility rules…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Marriage compatibility rules</h1>
        <p className="muted">
          Each row says which partner numbers a person with that Mulank matches. The engine checks both
          directions: <strong>both match</strong> gives a Strong Match, <strong>one matches</strong> gives a Good
          Match, and neither gives Not Matched.
        </p>
      </header>

      <div className="alert info">
        Changes take effect for every calculation immediately. Nothing about these rules is hard-coded in the app.
      </div>

      {Object.values(drafts)
        .sort((a, b) => a.driverNumber - b.driverNumber)
        .map((rule) => (
          <Card
            key={rule.id}
            title={`Mulank ${rule.driverNumber}`}
            action={
              <div className="btn-row">
                <label style={{ margin: 0 }}>
                  <input
                    type="checkbox"
                    style={{ width: 'auto', marginRight: 8, minHeight: 'auto' }}
                    disabled={!canWrite}
                    checked={rule.enabled}
                    onChange={(event) =>
                      setDrafts((current) => ({
                        ...current,
                        [rule.driverNumber]: { ...rule, enabled: event.target.checked },
                      }))
                    }
                  />
                  Enabled
                </label>
                {canWrite && (
                  <button
                    type="button"
                    className="btn-primary"
                    onClick={() => save(rule.driverNumber)}
                    disabled={savingNumber === rule.driverNumber}
                  >
                    {savingNumber === rule.driverNumber ? 'Saving…' : 'Save'}
                  </button>
                )}
              </div>
            }
          >
            <div className="field-row">
              <div className="field">
                <label>Compatible partner Mulank</label>
                <NumberPicker
                  selected={rule.compatibleMulank}
                  disabled={!canWrite}
                  onToggle={(value) => toggle(rule.driverNumber, 'compatibleMulank', value)}
                />
                <div className="hint">Tap a number to add or remove it.</div>
              </div>
              <div className="field">
                <label>Compatible partner Bhagyank</label>
                <NumberPicker
                  selected={rule.compatibleBhagyank}
                  disabled={!canWrite}
                  onToggle={(value) => toggle(rule.driverNumber, 'compatibleBhagyank', value)}
                />
                <div className="hint">A match through the Bhagyank is explained separately in the result.</div>
              </div>
            </div>

            <div className="field-row">
              {(['en', 'hi', 'mr'] as const).map((locale) => (
                <div className="field" key={locale}>
                  <label htmlFor={`note-${rule.driverNumber}-${locale}`}>
                    Note shown with the result ({locale.toUpperCase()})
                  </label>
                  <input
                    id={`note-${rule.driverNumber}-${locale}`}
                    disabled={!canWrite}
                    value={rule.notes?.[locale] ?? ''}
                    onChange={(event) =>
                      setDrafts((current) => ({
                        ...current,
                        [rule.driverNumber]: {
                          ...rule,
                          notes: { ...(rule.notes ?? {}), [locale]: event.target.value },
                        },
                      }))
                    }
                  />
                </div>
              ))}
            </div>
          </Card>
        ))}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
