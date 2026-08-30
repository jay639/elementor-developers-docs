import { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAsync } from '../lib/useAsync';
import { Card, ErrorState, ListField, Loading, LocaleTabs, NumberPicker, Toast } from '../components/ui';

interface NumberContent {
  id: string;
  number: number;
  locale: string;
  name: string;
  title: string;
  summary: string;
  personality: string;
  behaviour: string;
  strengths: string[];
  weaknesses: string[];
  career: string;
  relationships: string;
  general: string;
  luckyNumbers: number[];
  unfavourableNumbers: number[];
  colors: string[];
  notes: string | null;
  isPublished: boolean;
}

/** Editor for the interpretation of the numbers 1-9, per language. */
export function NumbersPage({ canWrite }: { canWrite: boolean }) {
  const [locale, setLocale] = useState('en');
  const [selected, setSelected] = useState(1);
  const [draft, setDraft] = useState<NumberContent | null>(null);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; tone: 'info' | 'error' } | null>(null);

  const { data, loading, error, reload } = useAsync(
    async () => (await api<NumberContent[]>('/admin/numerology/numbers', { query: { locale } })).data,
    [locale],
  );

  useEffect(() => {
    const row = data?.find((item) => item.number === selected) ?? null;
    setDraft(row ? { ...row } : null);
  }, [data, selected]);

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(timer);
  }, [toast]);

  const update = <K extends keyof NumberContent>(key: K, value: NumberContent[K]) =>
    setDraft((current) => (current ? { ...current, [key]: value } : current));

  const save = async () => {
    if (!draft) return;
    setSaving(true);
    try {
      const { id, number, locale: rowLocale, ...payload } = draft;
      void id;
      void rowLocale;
      await api(`/admin/numerology/numbers/${number}/${locale}`, { method: 'PUT', body: payload });
      setToast({ message: `Number ${number} saved. The app will show the new text immediately.`, tone: 'info' });
      await reload();
    } catch (caught) {
      setToast({ message: (caught as Error).message, tone: 'error' });
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Loading rows={8} label="Loading number content…" />;
  if (error) return <ErrorState message={error} onRetry={reload} />;

  return (
    <>
      <header style={{ marginBottom: 16 }}>
        <h1>Number content</h1>
        <p className="muted">
          The interpretation shown for each number in the app. Every field below is read from the database, so a
          change here reaches users without a new app release.
        </p>
      </header>

      <Card action={<LocaleTabs value={locale} onChange={setLocale} />}>
        <div className="btn-row" role="tablist" aria-label="Number">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((number) => (
            <button
              key={number}
              type="button"
              role="tab"
              aria-selected={selected === number}
              className={`number-chip ${selected === number ? 'on' : ''}`}
              onClick={() => setSelected(number)}
            >
              {number}
            </button>
          ))}
        </div>
      </Card>

      {!draft ? (
        <Card title={`Number ${selected}`}>
          <p className="muted">This number has not been written in this language yet.</p>
        </Card>
      ) : (
        <Card
          title={`Number ${draft.number} — ${draft.title}`}
          action={
            canWrite ? (
              <button type="button" className="btn-primary" onClick={save} disabled={saving}>
                {saving ? 'Saving…' : 'Save changes'}
              </button>
            ) : (
              <span className="badge muted">Read only</span>
            )
          }
        >
          <fieldset disabled={!canWrite} style={{ border: 0, padding: 0, margin: 0 }}>
            <div className="field-row">
              <div className="field">
                <label htmlFor="name">Name</label>
                <input id="name" value={draft.name} onChange={(event) => update('name', event.target.value)} />
              </div>
              <div className="field">
                <label htmlFor="title">Title</label>
                <input id="title" value={draft.title} onChange={(event) => update('title', event.target.value)} />
              </div>
            </div>

            <div className="field">
              <label htmlFor="summary">Summary</label>
              <textarea id="summary" value={draft.summary} onChange={(event) => update('summary', event.target.value)} />
            </div>

            <div className="field">
              <label htmlFor="personality">Personality</label>
              <textarea
                id="personality"
                value={draft.personality}
                onChange={(event) => update('personality', event.target.value)}
              />
            </div>

            <div className="field">
              <label htmlFor="behaviour">Behaviour</label>
              <textarea
                id="behaviour"
                value={draft.behaviour}
                onChange={(event) => update('behaviour', event.target.value)}
              />
            </div>

            <ListField
              label="Strengths"
              value={draft.strengths}
              onChange={(value) => update('strengths', value)}
              hint="Separate each item with a comma."
            />
            <ListField label="Weaknesses" value={draft.weaknesses} onChange={(value) => update('weaknesses', value)} />

            <div className="field">
              <label htmlFor="career">Career tendencies</label>
              <textarea id="career" value={draft.career} onChange={(event) => update('career', event.target.value)} />
            </div>

            <div className="field">
              <label htmlFor="relationships">Relationship tendencies</label>
              <textarea
                id="relationships"
                value={draft.relationships}
                onChange={(event) => update('relationships', event.target.value)}
              />
            </div>

            <div className="field">
              <label htmlFor="general">General interpretation</label>
              <textarea id="general" value={draft.general} onChange={(event) => update('general', event.target.value)} />
            </div>

            <div className="field-row">
              <div className="field">
                <label>Lucky numbers</label>
                <NumberPicker
                  selected={draft.luckyNumbers}
                  tone="friendly"
                  disabled={!canWrite}
                  onToggle={(value) =>
                    update(
                      'luckyNumbers',
                      draft.luckyNumbers.includes(value)
                        ? draft.luckyNumbers.filter((item) => item !== value)
                        : [...draft.luckyNumbers, value].sort((a, b) => a - b),
                    )
                  }
                />
              </div>
              <div className="field">
                <label>Unfavourable numbers</label>
                <NumberPicker
                  selected={draft.unfavourableNumbers}
                  tone="unfriendly"
                  disabled={!canWrite}
                  onToggle={(value) =>
                    update(
                      'unfavourableNumbers',
                      draft.unfavourableNumbers.includes(value)
                        ? draft.unfavourableNumbers.filter((item) => item !== value)
                        : [...draft.unfavourableNumbers, value].sort((a, b) => a - b),
                    )
                  }
                />
              </div>
            </div>

            <ListField label="Recommended colours" value={draft.colors} onChange={(value) => update('colors', value)} />

            <div className="field">
              <label htmlFor="notes">Additional notes</label>
              <input id="notes" value={draft.notes ?? ''} onChange={(event) => update('notes', event.target.value)} />
            </div>

            <div className="field">
              <label htmlFor="published">
                <input
                  id="published"
                  type="checkbox"
                  style={{ width: 'auto', marginRight: 8, minHeight: 'auto' }}
                  checked={draft.isPublished}
                  onChange={(event) => update('isPublished', event.target.checked)}
                />
                Published (unpublished content is hidden from the app)
              </label>
            </div>
          </fieldset>
        </Card>
      )}

      {toast && <Toast message={toast.message} tone={toast.tone} />}
    </>
  );
}
