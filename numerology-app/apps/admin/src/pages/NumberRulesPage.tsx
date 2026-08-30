import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, Loading, NumberPicker, Toast } from '../components/ui';

interface NumberRule {
  id: string;
  baseNumber: number;
  friendly: number[];
  neutral: number[];
  unfriendly: number[];
  enabled: boolean;
}

/**
 * Friendly / neutral / unfriendly relationships used by the Lucky Number Finder
 * and by the name-versus-date-of-birth comparison.
 */
export function NumberRulesPage({ canWrite }: { canWrite: boolean }) {
  const [drafts, setDrafts] = useState<Record<number, NumberRule>>({});
  const [savingNumber, setSavingNumber] = useState<number | null>(null);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<NumberRule[]>('/admin/number-rules')).data,
    [],
  );

  useEffect(() => {
    if (data) setDrafts(Object.fromEntries(data.map((rule) => [rule.baseNumber, { ...rule }])));
  }, [data]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  /** A number belongs to exactly one category, so selecting it clears the others. */
  const assign = (baseNumber: number, category: 'friendly' | 'neutral' | 'unfriendly', value: number) => {
    setDrafts((current) => {
      const rule = current[baseNumber];
      if (!rule) return current;
      const next: NumberRule = {
        ...rule,
        friendly: rule.friendly.filter((item) => item !== value),
        neutral: rule.neutral.filter((item) => item !== value),
        unfriendly: rule.unfriendly.filter((item) => item !== value),
      };
      if (!rule[category].includes(value)) {
        next[category] = [...next[category], value].sort((a, b) => a - b);
      }
      return { ...current, [baseNumber]: next };
    });
  };

  const save = async (baseNumber: number) => {
    const rule = drafts[baseNumber];
    if (!rule) return;
    setSavingNumber(baseNumber);
    try {
      await api(`/admin/number-rules/${baseNumber}`, {
        method: 'PUT',
        body: {
          friendly: rule.friendly,
          neutral: rule.neutral,
          unfriendly: rule.unfriendly,
          enabled: rule.enabled,
        },
      });
      setToast({ message: `Rule for number ${baseNumber} saved.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSavingNumber(null);
    }
  };

  if (loading) return <Loading rows={9} label="Loading number rules…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Number compatibility</h1>
        <p className="muted">
          Used when a vehicle, mobile or house number is compared with a user&apos;s Mulank and Bhagyank. Each number
          1-9 must appear in exactly one category.
        </p>
      </header>

      {Object.values(drafts)
        .sort((a, b) => a.baseNumber - b.baseNumber)
        .map((rule) => {
          const unassigned = [1, 2, 3, 4, 5, 6, 7, 8, 9].filter(
            (number) =>
              !rule.friendly.includes(number) &&
              !rule.neutral.includes(number) &&
              !rule.unfriendly.includes(number),
          );
          return (
            <Card
              key={rule.id}
              title={`Number ${rule.baseNumber}`}
              action={
                canWrite && (
                  <button
                    type="button"
                    className="btn-primary"
                    onClick={() => save(rule.baseNumber)}
                    disabled={savingNumber === rule.baseNumber || unassigned.length > 0}
                  >
                    {savingNumber === rule.baseNumber ? 'Saving…' : 'Save'}
                  </button>
                )
              }
            >
              {unassigned.length > 0 && (
                <div className="alert warning">
                  Assign {unassigned.join(', ')} to a category before saving.
                </div>
              )}
              <div className="field-row">
                <div className="field">
                  <label>Friendly (strong match)</label>
                  <NumberPicker
                    selected={rule.friendly}
                    tone="friendly"
                    disabled={!canWrite}
                    onToggle={(value) => assign(rule.baseNumber, 'friendly', value)}
                  />
                </div>
                <div className="field">
                  <label>Neutral</label>
                  <NumberPicker
                    selected={rule.neutral}
                    disabled={!canWrite}
                    onToggle={(value) => assign(rule.baseNumber, 'neutral', value)}
                  />
                </div>
                <div className="field">
                  <label>Unfriendly (weak match)</label>
                  <NumberPicker
                    selected={rule.unfriendly}
                    tone="unfriendly"
                    disabled={!canWrite}
                    onToggle={(value) => assign(rule.baseNumber, 'unfriendly', value)}
                  />
                </div>
              </div>
            </Card>
          );
        })}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
